import 'package:faculty_app/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String? selectedDepartment;
  String? selectedLevel;
  String? selectedType;

  // bool latestUploads = true;
  // String selectedSort = "Newest First"; // Default sort

  final List<String> departments = [
    'All',
    "Architecture",
    "Building",
    "Urban & Regional Planning",
    "Estate Management",
    "Quantity Surveying"
  ];
  final List<String> levels = [
    "100 Level",
    "200 Level",
    "300 Level",
    "400 Level",
    "500 Level"
  ];
  final List<String> documentTypes = [
    "Lecture Notes",
    "Past Questions",
  ];
  final TextEditingController courseController = TextEditingController();
  final List<String> fileTypes = ["PDF", "Word Doc", "PowerPoint"];
  final List<String> sortOptions = [
    "Newest First",
    "Oldest First",
    // "Alphabetical (A-Z)",
    // "Alphabetical (Z-A)",
    // "File Size (Largest First)",
    // "File Size (Smallest First)"
  ];

  void resetFilters() {
    setState(() {
      selectedDepartment = null;
      courseController.clear();
      selectedLevel = null;
      selectedType = null;
      // latestUploads = true;
      // selectedSort = "Newest First";
    });
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => BottomNavBar(
                  initialIndex: 2,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.70,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(
                height: 5,
              ),
              // TabBar(
              //   labelColor: Color(0xff347928),
              //   labelStyle:
              //       TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              //   indicator: UnderlineTabIndicator(
              //     borderSide: BorderSide(
              //       color: Color(0xff347928), // Change color here
              //       width: 3.0, // Change thickness (weight) here
              //     ),
              //     insets: EdgeInsets.symmetric(
              //         horizontal: MediaQuery.of(context).size.width *
              //             0.125), // 50% of default tab width
              //   ),
              //   tabs: [
              //     Tab(text: "FILTER"),
              //     Tab(text: "SORT"),
              //   ],
              // ),
              SizedBox(
                height: 20,
              ),
              Text(
                'FILTER BY',
                style: TextStyle(
                    color: Color(0xff347928),
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      buildDropdown(
                          "Department", departments, selectedDepartment, (val) {
                        setState(() => selectedDepartment = val);
                      }),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Course Code',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              buildTextFormField(
                                  courseController, 'e.g BLD 213'),
                            ],
                          )),
                          SizedBox(width: 10),
                          Expanded(
                            child: buildDropdown("Level", levels, selectedLevel,
                                (val) {
                              setState(() => selectedLevel = val);
                            }),
                          ),
                        ],
                      ),
                      buildDropdown(
                          "Document Type", documentTypes, selectedType, (val) {
                        setState(() => selectedType = val);
                      }),
                    ],
                  ),
                ),
              ),

              // Apply & Reset Buttons
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: resetFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Reset",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xffC7FFD8),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context, {
                            "department": selectedDepartment,
                            "course_code": courseController.text,
                            "level": selectedLevel,
                            "type": selectedType,
                            // "latestUploads": latestUploads,
                            // "sortBy": selectedSort,
                          });
                        },
                        child: Text("Apply Filters",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTextFormField(controller, titleHint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
            color: Color(0xff347928),
            width: 1.5,
          ),
        ),
        labelText: titleHint,
        labelStyle: TextStyle(color: Colors.black),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedItem,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 5),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            value: selectedItem,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: Color(0xff347928),
                  width: 1.5,
                ),
              ),
            ),
            isExpanded: false,
            items: items
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                    )))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

void showFilterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => FilterModal(),
  ).then((selectedFilters) {
    if (selectedFilters != null) {
      print("Filters Applied: $selectedFilters");
    }
  });
}
