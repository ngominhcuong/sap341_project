import 'package:flutter/material.dart';

class SearchableDropdown extends StatefulWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String?> onChanged;
  final String label;
  final Color? primaryColor;

  const SearchableDropdown({
    Key? key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    required this.label,
    this.primaryColor,
  }) : super(key: key);

  @override
  _SearchableDropdownState createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDropdown() {
    _searchController.clear();
    List<String> filteredOptions = List<String>.from(widget.options);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn ${widget.label}',
                        style: TextStyle(
                          color: widget.primaryColor ?? Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ô tìm kiếm mới ở thanh dropdown
                      TextField(
                        controller: _searchController,
                        onChanged: (query) {
                          dialogSetState(() {
                            if (query.trim().isEmpty) {
                              filteredOptions = List<String>.from(
                                widget.options,
                              );
                            } else {
                              filteredOptions = widget.options
                                  .where(
                                    (option) => option.toLowerCase().contains(
                                      query.trim().toLowerCase(),
                                    ),
                                  )
                                  .toList();
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: widget.primaryColor ?? Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filteredOptions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Không tìm thấy kết quả',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 300),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(filteredOptions.length, (
                                index,
                              ) {
                                final option = filteredOptions[index];
                                final isSelected =
                                    option == widget.selectedValue;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (widget.primaryColor ?? Colors.green)
                                              .withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color:
                                                widget.primaryColor ??
                                                Colors.green,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      option,
                                      style: TextStyle(
                                        color: isSelected
                                            ? widget.primaryColor ??
                                                  Colors.green
                                            : Colors.black87,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? Icon(
                                            Icons.check,
                                            color:
                                                widget.primaryColor ??
                                                Colors.green,
                                          )
                                        : null,
                                    onTap: () {
                                      widget.onChanged(option);
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Đóng',
                            style: TextStyle(
                              color: widget.primaryColor ?? Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: _openDropdown,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.selectedValue,
                    style: TextStyle(
                      color: widget.primaryColor ?? Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.primaryColor ?? Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
