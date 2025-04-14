import 'package:flutter/material.dart';

class HubContainer extends StatelessWidget {
  final String title;
  final String image;
  final String description;

  const HubContainer(
      {super.key,
      required this.title,
      required this.image,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xffDBDBDB),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                width: 40,
                height: 40,
                'assets/images/$image',
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 5),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
