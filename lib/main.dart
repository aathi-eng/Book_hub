import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to Book Hub!'),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  DateTime? selectedDate;
  String selectedGender = 'Male';
  String selectedRole = 'buyer';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool showOtpField = false;
  String? verificationId;

  final List<String> roles = ['buyer', 'seller', 'admin'];
  final List<String> genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // Email validation
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation
  String? validatePassword(String password) {
    List<String> errors = [];

    if (password.length < 6) {
      errors.add('at least 6 characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('at least one uppercase letter');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('at least one special character');
    }

    if (errors.isNotEmpty) {
      return 'Password must contain ${errors.join(', ')}';
    }
    return null;
  }

  // Phone validation for Indian numbers
  String? validatePhone(String phone) {
    if (!RegExp(r'^\+91[0-9]{10}$').hasMatch(phone)) {
      return 'Please enter valid Indian mobile number (10 digits with +91)';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Generate and send OTP
  Future<void> sendOTP() async {
    if (!_validateInitialFields()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final email = emailController.text.trim();

      // Generate random 6-digit OTP
      final random = Random(); // This is correct
      final otp = List.generate(6, (_) => random.nextInt(10)).join();

      // Send OTP via Firebase Auth
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://flutterapplication2.page.link/finishSignUp?email=$email',
          handleCodeInApp: true,
          androidPackageName: 'com.example.flutter_application_1',
          androidInstallApp: true,
          androidMinimumVersion: '12',
        ),
      );

      verificationId = otp;

      if (mounted) {
        setState(() {
          showOtpField = true;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to your email')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  bool _validateInitialFields() {
    // Validate all required fields
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        addressController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return false;
    }

    // Validate email
    if (!isValidEmail(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return false;
    }

    // Validate password
    String? passwordError = validatePassword(passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return false;
    }

    // Validate confirm password
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return false;
    }

    // Validate phone number
    if (!phoneController.text.startsWith('+91')) {
      phoneController.text = '+91${phoneController.text}';
    }
    String? phoneError = validatePhone(phoneController.text);
    if (phoneError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneError)),
      );
      return false;
    }

    return true;
  }

  Future<void> verifyOTPAndSignUp() async {
    if (otpController.text != verificationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
      return;
    }

    await signUpUser();
  }

  Future<void> signUpUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Create user account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Add user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'FirstName': firstNameController.text,
        'LastName': lastNameController.text,
        'Email': emailController.text.trim(),
        'Phone': phoneController.text,
        'Address': addressController.text,
        'Gender': selectedGender,
        'Role': selectedRole,
        'Dateofbirth': selectedDate?.toIso8601String(),
        'CreatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(179),
                Colors.black.withAlpha(128),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Create an Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // First Name Field
                    _buildTextField(
                      controller: firstNameController,
                      label: 'First Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),

                    // Last Name Field
                    _buildTextField(
                      controller: lastNameController,
                      label: 'Last Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),

                    // Phone Field
                    _buildTextField(
                      controller: phoneController,
                      label: 'Phone Number (+91)',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    _buildTextField(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    _buildTextField(
                      controller: passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Field
                    _buildTextField(
                      controller: confirmPasswordController,
                      label: 'Confirm Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address Field
                    _buildTextField(
                      controller: addressController,
                      label: 'Address',
                      icon: Icons.home,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Role Selection
                    _buildDropdown(
                      value: selectedRole,
                      items: roles,
                      label: 'Select Role',
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedRole = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Selection
                    _buildDropdown(
                      value: selectedGender,
                      items: genders,
                      label: 'Select Gender',
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedGender = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(
                          selectedDate == null
                              ? 'Select Date of Birth'
                              : DateFormat('MMM dd, yyyy')
                                  .format(selectedDate!),
                        ),
                        onTap: () => _selectDate(context),
                      ),
                    ),

                    // OTP Field
                    if (showOtpField) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: otpController,
                        label: 'Enter OTP',
                        icon: Icons.security,
                        keyboardType: TextInputType.number,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sign Up/Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (!showOtpField) {
                                  sendOTP();
                                } else {
                                  verifyOTPAndSignUp();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                showOtpField ? 'Verify & Sign Up' : 'Send OTP',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(label),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (!emailController.text.contains('@')) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'The email address is badly formatted.',
        );
      }

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(179),
                Colors.black.withAlpha(128),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/logo.png',
                      height: 120,
                      width: 120,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome to Book Hub',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email ID',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        obscureText: _obscurePassword,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: resetPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Log In',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpPage()),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
