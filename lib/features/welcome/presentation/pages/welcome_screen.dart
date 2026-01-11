import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/pages/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.surface, theme.scaffoldBackgroundColor],
          ),
        ),
        child: Stack(
          children: [
            // Altın parıltı efekti
            Positioned.fill(
              child: CustomPaint(painter: GoldenSparklesPainter()),
            ),

            // Ana içerik
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Logo (Alman kartalı)
                  Container(
                    width: size.width * 0.5,
                    height: size.width * 0.5,
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Başlık
                  Text(
                    'ALMANCA',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 2,
                    ),
                  ),

                  Text(
                    'ÖĞREN',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Alt başlık
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PREMIUM DİL EĞİTİMİ',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        letterSpacing: 2,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Başla butonu - Gradient effect
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4824A), Color(0xFFB85342)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4824A).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Center(
                            child: Text(
                              'Başla',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Altın parıltı efekti için custom painter
class GoldenSparklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Rastgele parıltılar
    for (int i = 0; i < 50; i++) {
      final x = (i * 137.5) % size.width;
      final y = (i * 197.3) % size.height;
      final radius = (i % 3) + 1.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
