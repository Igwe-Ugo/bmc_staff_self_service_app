import 'package:flutter/material.dart';

class BMCHome extends StatefulWidget {
  const BMCHome({super.key});

  @override
  State<BMCHome> createState() => _BMCHomeState();
}

class _BMCHomeState extends State<BMCHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(30, 50, 30, 40),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _topNavBar(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _topNavBar(BuildContext context){
    return Row(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: Image.asset('assets/images/profile_pic.png', scale: 0.5),
            ),
            const SizedBox(width: 15,),
            Text(
              'Profile',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w700,
                fontSize: 14
              ),
            )
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 23, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20)
          ),
          child: Row(
            children: [
              Text(
                'Active',
                style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    fontSize: 12
                ),
              ),
              const SizedBox(width: 5,),
              CircleAvatar(
                radius: 5,
                backgroundColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
