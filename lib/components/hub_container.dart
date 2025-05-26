import 'package:flutter/material.dart';

class HubContainer extends StatelessWidget {
  final String title;
  final Icon icon;
  final String description;

  const HubContainer(
      {super.key,
      required this.title,
      required this.icon,
      required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Colors.black, width: .5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(5.0)),
                      border: Border.all(color: Colors.black, width: 1)),
                  padding: const EdgeInsets.all(5.0),
                  child: icon),
              SizedBox(height: 13),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
