
import 'package:flutter/cupertino.dart';

class Footer extends StatefulWidget {
  const Footer({super.key});

  @override
  State<Footer> createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  @override
  Widget build(BuildContext context) {
    return _buildFooter();
  }
}


 const Color headerGreen = Color(0xFF12261C);

 const Color borderGreen = Color(0xFF234232);


 const Color mutedText = Color(0xFF8A9A90);



Widget _buildFooter()
{
  return Container(
    width: double.infinity,

    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),

    decoration: const BoxDecoration(
      color: headerGreen,

      border: Border(
        top: BorderSide(
          color: borderGreen,
        ),
      ),
    ),

    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 18,
      runSpacing: 6,

      children: const [

        Text(
          "© 2026",
          style: TextStyle(
            color: mutedText,
            fontSize: 11,
          ),
        ),

        Text(
          "Built for a better experience",
          style: TextStyle(
            color: mutedText,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}
