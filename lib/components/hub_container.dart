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
        elevation: 2,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Colors.black, width: .5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                width: 30,
                height: 30,
                'assets/images/$image',
              ),
              SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              SizedBox(height: 5),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(color: Colors.grey[800], fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
