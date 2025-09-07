import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/animated_logo.dart';
import '../../../core/widgets/powered_by_branding.dart';
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedLogo(
              size: 28.0,
              showText: false,
              autoAnimate: true,
            ),
            const SizedBox(width: 8),
            const Text('Register'),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Animated Logo
                  Center(
                    child: AnimatedLogo(
                      size: 100.0,
                      showText: true,
                      autoAnimate: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please provide your details to register',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
              
              // Basic Information
              Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.3,
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
              Text(
                'Aadhaar Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.3,
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
              
              
              ElevatedButton(
                onPressed: authState.isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: authState.isLoading
                    ? null
                    : () => Navigator.of(context).pushReplacementNamed(AppRouter.login),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Powered by branding
              const PoweredByBranding(
                textColor: Colors.grey,
                textSize: 11.0,
                imageHeight: 16.0,
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
