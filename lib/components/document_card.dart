import 'package:flutter/material.dart';

class DocumentCard extends StatelessWidget {
  const DocumentCard(
      {super.key,
      required this.imageText,
      required this.documentName,
      required this.documentSize,
      required this.date});

  final String imageText;
  final String documentName;
  final String documentSize;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.grey, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10.0)),
                    ),
                    padding: const EdgeInsets.all(7.0),
                    child: Image.asset(
                      imageText,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentName,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        '$documentSize  |  $date',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.download,
                color: Colors.black,
                size: 22,
              )
            ],
          ),
        ),
      ),
    );
  }
}
