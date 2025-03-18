import 'package:flutter/material.dart';

class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  String? selectedDepartment;
  String? selectedCourse;
  String? selectedLevel;
  String? selectedType;
  String? selectedFileType;
  bool latestUploads = true;
  String selectedSort = "Newest First"; // Default sort

  final List<String> departments = [
    "Architecture",
    "Building",
    "Urban Planning"
  ];
  final List<String> courses = ["BLD 201", "ARC 301", "URP 302"];
  final List<String> levels = ["100 Level", "200 Level", "300 Level"];
  final List<String> documentTypes = [
    "Lecture Notes",
    "Past Questions",
    "Slides"
  ];
  final List<String> fileTypes = ["PDF", "Word Doc", "PowerPoint"];
  final List<String> sortOptions = [
    "Newest First",
    "Oldest First",
    "Alphabetical (A-Z)",
    "Alphabetical (Z-A)",
    "File Size (Largest First)",
    "File Size (Smallest First)"
  ];

  void resetFilters() {
    setState(() {
      selectedDepartment = null;
      selectedCourse = null;
      selectedLevel = null;
      selectedType = null;
      selectedFileType = null;
      latestUploads = true;
      selectedSort = "Newest First";
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.70,
      expand: false,
      builder: (context, scrollController) {
        return DefaultTabController(
          length: 2,
          child: Container(
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
                SizedBox(height: 5,),
                TabBar(
                  labelColor: Color(0xff347928),
                  labelStyle:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      color: Color(0xff347928), // Change color here
                      width: 3.0, // Change thickness (weight) here
                    ),
                    insets: EdgeInsets.symmetric(
                        horizontal: MediaQuery
                            .of(context)
                            .size
                            .width *
                            0.125), // 50% of default tab width
                  ),
                  tabs: [
                    Tab(text: "FILTER"),
                    Tab(text: "SORT"),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Filter Tab
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ListView(
                          controller: scrollController,
                          children: [
                            buildDropdown(
                                "Department", departments, selectedDepartment,
                                    (val) {
                                  setState(() => selectedDepartment = val);
                                }),
                            Row(
                              children: [
                                Expanded(
                                  child: buildDropdown(
                                      "Course", courses, selectedCourse, (val) {
                                    setState(() => selectedCourse = val);
                                  }),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: buildDropdown(
                                      "Level", levels, selectedLevel, (val) {
                                    setState(() => selectedLevel = val);
                                  }),
                                ),
                              ],
                            ),
                            buildDropdown(
                                "Document Type", documentTypes, selectedType,
                                    (val) {
                                  setState(() => selectedType = val);
                                }),
                            buildDropdown(
                                "File Type", fileTypes, selectedFileType,
                                    (val) {
                                  setState(() => selectedFileType = val);
                                }),
                          ],
                        ),
                      ),

                      // Sort Tab
                      ListView(
                        controller: scrollController,
                        children: sortOptions.map((sortOption) {
                          return RadioListTile(
                            activeColor: Color(0xff347928),
                            title: Text(sortOption),
                            value: sortOption,
                            groupValue: selectedSort,
                            onChanged: (value) {
                              setState(() {
                                selectedSort = value!;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
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
                                color: Colors.white,
                                fontWeight: FontWeight.w900),
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
                              "course": selectedCourse,
                              "level": selectedLevel,
                              "type": selectedType,
                              "fileType": selectedFileType,
                              "latestUploads": latestUploads,
                              "sortBy": selectedSort,
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
          ),
        );
      },
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
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
            value: selectedItem,
            decoration: InputDecoration(
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                  color: Color(0xff347928),
                  width: 1.5,
                ),
              ),
            ),
            isExpanded: false,
            items: items
                .map((e) =>
                DropdownMenuItem(
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
