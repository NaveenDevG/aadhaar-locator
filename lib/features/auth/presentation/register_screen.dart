import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../../../core/services/firebase_connectivity_service.dart';
import '../services/aadhaar_validator.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _aadhaarNameController = TextEditingController();
  final _aadhaarNumberController = TextEditingController();
  
  bool _obscurePassword = true;
  DateTime? _selectedDob;
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _aadhaarNameController.dispose();
    _aadhaarNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  String? _validateAadhaarName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar name is required';
    }
    if (!AadhaarValidator.isValidName(value)) {
      return 'Please enter your full name as per Aadhaar (at least 2 words)';
    }
    return null;
  }

  String? _validateAadhaarNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Aadhaar number is required';
    }
    if (!AadhaarValidator.isValidNumber(value)) {
      return 'Please enter a valid 12-digit Aadhaar number';
    }
    return null;
  }

  String? _validateDob() {
    if (_selectedDob == null) {
      return 'Date of birth is required';
    }
    if (!AadhaarValidator.isValidDob(_selectedDob!)) {
      return 'You must be at least 18 years old';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_validateDob() != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_validateDob()!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        aadhaarName: _aadhaarNameController.text.trim(),
        aadhaarNumber: _aadhaarNumberController.text.trim(),
        aadhaarDob: _selectedDob!,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful! Please login to continue.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = e.toString();
      Color backgroundColor = Colors.red;
      
      // Handle specific reCAPTCHA errors
      if (errorMessage.contains('reCAPTCHA') || 
          errorMessage.contains('network error') ||
          errorMessage.contains('network-request-failed')) {
        errorMessage = '''
Registration failed due to reCAPTCHA verification issues.

This is common in Android emulators. Try:
• Using a real device
• Checking internet connection
• Using the "Fill Test Data" button below
        ''';
        backgroundColor = Colors.orange;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final connectivityService = FirebaseConnectivityService();
      final status = await connectivityService.getConnectivityStatus();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Firebase Connectivity Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connected: ${status['isConnected'] ? '✅ Yes' : '❌ No'}'),
              const SizedBox(height: 8),
              if (status['lastError'] != null) ...[
                Text('Last Error: ${status['lastError']}'),
                const SizedBox(height: 8),
              ],
              if (status['recommendations'].isNotEmpty) ...[
                const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...status['recommendations'].map((rec) => Text('• $rec')),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connectivity check failed: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_add,
                size: 80,
                color: Colors.indigo,
              ),
              const SizedBox(height: 24),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide your details to register',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Development Info (only show in development)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Development Note',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you encounter reCAPTCHA errors in the emulator, try using a real device or use the "Fill Test Data" button below.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Basic Information
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.required(value, 'Full name'),
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.email,
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.password,
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 32),
              
              // Aadhaar Information
              const Text(
                'Aadhaar Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please provide your Aadhaar details for verification',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _aadhaarNameController,
                decoration: const InputDecoration(
                  labelText: 'Name as per Aadhaar',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                  helperText: 'Enter your full name exactly as it appears on your Aadhaar card',
                ),
                validator: _validateAadhaarName,
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _aadhaarNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Aadhaar Number',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                  helperText: 'Enter 12-digit Aadhaar number',
                ),
                validator: _validateAadhaarNumber,
                enabled: !authState.isLoading,
              ),
              const SizedBox(height: 16),
              
              // Date of Birth
              InkWell(
                onTap: authState.isLoading ? null : _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    helperText: 'You must be at least 18 years old',
                  ),
                  child: Text(
                    _selectedDob == null
                        ? 'Select Date of Birth'
                        : _dateFormat.format(_selectedDob!),
                    style: TextStyle(
                      color: _selectedDob == null ? Colors.grey : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              if (authState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    authState.error!,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Connectivity check button
              OutlinedButton.icon(
                onPressed: authState.isLoading ? null : _checkConnectivity,
                icon: const Icon(Icons.wifi_find),
                label: const Text('Check Firebase Connection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: authState.isLoading ? null : _register,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register'),
              ),
              const SizedBox(height: 16),
              
              // Test User Button (for development)
              OutlinedButton(
                onPressed: authState.isLoading ? null : _createTestUser,
                child: const Text('Fill Test Data (Development)'),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () => Navigator.of(context).pushReplacementNamed(AppRouter.login),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Create a test user for development
  Future<void> _createTestUser() async {
    try {
      // Pre-fill with test data
      _emailController.text = 'test.user@example.com';
      _passwordController.text = 'TestPassword123!';
      _nameController.text = 'Test User';
      _aadhaarNameController.text = 'Test User Name';
      _aadhaarNumberController.text = '123456789012';
      
      // Set a valid DOB (25 years ago)
      final now = DateTime.now();
      _selectedDob = DateTime(now.year - 25, now.month, now.day);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test data filled! Try registering again.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
