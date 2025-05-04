import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../controllers/transaction_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/budget_controller.dart';
import '../models/transaction.dart';
import '../utils/currency_utils.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String _selectedCategoryId = '';
  DateTime _selectedDate = DateTime.now();
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _receiptImagePath;

  final TransactionController _transactionController =
      Get.find<TransactionController>();
  final CategoryController _categoryController = Get.find<CategoryController>();
  final BudgetController _budgetController = Get.find<BudgetController>();

  @override
  void initState() {
    super.initState();
    // Initialize with today's date
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Set a default category if available
    if (_categoryController.categories.isNotEmpty) {
      _selectedCategoryId = _categoryController.categories.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _type == TransactionType.expense ? 'Add Expense' : 'Add Income'),
      ),
      body: Obx(() {
        if (_categoryController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_categoryController.categories.isEmpty) {
          return const Center(
            child: Text('Please add categories first!'),
          );
        }

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transaction Type Selector
                _buildTransactionTypeSelector(),

                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: false),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (!CurrencyUtils.isValidAmount(value)) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category Dropdown
                _buildCategoryDropdown(),

                const SizedBox(height: 16),

                // Date Picker Field
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    hintText: 'Select date',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),

                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                // Payment Method Dropdown
                _buildPaymentMethodDropdown(),

                const SizedBox(height: 16),

                // Receipt Image
                _buildReceiptImagePicker(),

                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitTransaction,
                  child: const Text('Add Transaction'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() {
              _type = TransactionType.expense;
            }),
            style: ElevatedButton.styleFrom(
              elevation: _type == TransactionType.expense ? 2 : 0,
              backgroundColor: _type == TransactionType.expense
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Expense',
                style: TextStyle(
                  color: _type == TransactionType.expense
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() {
              _type = TransactionType.income;
            }),
            style: ElevatedButton.styleFrom(
              elevation: _type == TransactionType.income ? 2 : 0,
              backgroundColor: _type == TransactionType.income
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Income',
                style: TextStyle(
                  color: _type == TransactionType.income
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
      ),
      value: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
      items: _categoryController.categories
          .map((category) => DropdownMenuItem(
                value: category.id,
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 24),
                    const SizedBox(width: 12),
                    Text(category.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedCategoryId = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<PaymentMethod>(
      decoration: const InputDecoration(
        labelText: 'Payment Method',
        prefixIcon: Icon(Icons.payment),
      ),
      value: _paymentMethod,
      items: PaymentMethod.values
          .map((method) => DropdownMenuItem(
                value: method,
                child: Text(method.name.capitalize!),
              ))
          .toList(),
      onChanged: (PaymentMethod? value) {
        if (value != null) {
          setState(() {
            _paymentMethod = value;
          });
        }
      },
    );
  }

  Widget _buildReceiptImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt Image (Optional)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_receiptImagePath != null)
              Expanded(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_receiptImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _receiptImagePath = null;
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: InkWell(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add Receipt',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request appropriate permission based on source
    PermissionStatus status;

    if (source == ImageSource.camera) {
      status = await Permission.camera.request();
    } else {
      // For gallery access, request both storage and photos permissions
      // This ensures compatibility across different Android versions
      if (Platform.isAndroid) {
        // Request both types of permissions for Android
        await Permission.storage.request();
        status = await Permission.photos.request();
      } else {
        // For iOS, just request photos permission
        status = await Permission.photos.request();
      }
    }

    if (source == ImageSource.gallery && Platform.isAndroid) {
      // For Android gallery, continue regardless of permission result
      // as some Android versions will grant through storage and some through photos
      final ImagePicker picker = ImagePicker();
      try {
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _receiptImagePath = image.path;
          });
        }
      } catch (e) {
        // Show error if permission is actually denied
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to access gallery. Please check app permissions in system settings.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Camera and iOS paths
      if (status.isGranted) {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          setState(() {
            _receiptImagePath = image.path;
          });
        }
      } else {
        // Show error message if permission is denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${source == ImageSource.camera ? 'Camera' : 'Photos'} permission is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  void _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      // Create a new transaction from form data
      final transaction = Transaction(
        amount: CurrencyUtils.parseAmount(_amountController.text),
        type: _type,
        date: _selectedDate,
        category: _selectedCategoryId,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        paymentMethod: _paymentMethod,
        receiptImagePath: _receiptImagePath,
      );

      // Add transaction
      await _transactionController.addTransaction(transaction);

      // Return here since addTransaction already calls Get.back()
      return;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}
