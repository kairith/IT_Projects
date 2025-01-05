import 'dart:io';

enum itemType { 
  APPETIZER, 
  MAINCOURSE, 
  DESSERT, 
  BEVERAGE 
}

enum PaymentMethod {
  ABA,
  ACLEDA, 
  CASH
}

enum OrderStatus {
  Pending,
  InProgress,
  Ready,
  Completed,
  Canceled,
}

enum ReservationStatus {
  pending,
  confirmed,
  canceled,
  completed,
}

class MenuItem {
  final String _id;
  final String _name;
  final double _price;
  String _description;
  final itemType _type;

  MenuItem({
    required String id,
    required String name,
    required double price,
    String description = '',
    required itemType type,
  })  : _id = id,
        _name = name,
        _price = price,
        _description = description,
        _type = type;

  String get id => _id;
  String get name => _name;
  double get price => _price;
  String get description => _description;
  itemType get type => _type;

  @override
  String toString() {
    return 'MenuItem{id: $_id, name: $_name, price: $_price, '
        'description: $_description, type: $_type}';
  }
}

class OrderedItem {
  final MenuItem menuItem;
  final int quantity;

  OrderedItem({
    required this.menuItem,
    required this.quantity,
  });

  double get totalPrice => menuItem.price * quantity;
}

class Menu {
  final List<MenuItem> _items;

  Menu() : _items = [];

  void addItem(MenuItem item) {
    _items.add(item);
  }

  bool removeItem(String id) {
    int initialLength = _items.length;
    _items.removeWhere((item) => item.id == id);
    return _items.length < initialLength;
  }

  List<MenuItem> get items => List.unmodifiable(_items);

  @override
  String toString() {
    return 'Menu{items: $_items}';
  }
}

class Payment {
  final String _paymentId;
  final String _orderId;
  final double _amount;
  final DateTime _paymentDate;
  final PaymentMethod _paymentMethod;
  double _change;
  bool _isProcessed;

  Payment({
    required String paymentId,
    required String orderId,
    required double amount,
    required PaymentMethod paymentMethod,
  })  : _paymentId = paymentId,
        _orderId = orderId,
        _amount = amount,
        _paymentMethod = paymentMethod,
        _paymentDate = DateTime.now(),
        _change = 0.0,
        _isProcessed = false;

  String get paymentId => _paymentId;
  String get orderId => _orderId;
  double get amount => _amount;
  DateTime get paymentDate => _paymentDate;
  PaymentMethod get paymentMethod => _paymentMethod;
  bool get isProcessed => _isProcessed;
  double get change => _change;

  void processPayment(double totalAmount) {
    if (_amount >= totalAmount) {
      _change = _amount - totalAmount; // Calculate change
      _isProcessed = true;
    } else {
      throw Exception(
          'Insufficient payment. Required: $totalAmount, Provided: $_amount');
    }
  }

  @override
  String toString() {
    return 'Payment{paymentId: $_paymentId, orderId: $_orderId, '
        'amount: $_amount, paymentDate: $_paymentDate, '
        'paymentMethod: $_paymentMethod, change: $_change, '
        'isProcessed: $_isProcessed}';
  }
}

class Customer {
  final String _id;
  final String _name;
  final String _phoneNumber;

  Customer({
    required String id,
    required String name,
    required String phoneNumber,
  })  : _id = id,
        _name = name,
        _phoneNumber = phoneNumber;

  String get id => _id;
  String get name => _name;
  String get phoneNumber => _phoneNumber;

  @override
  String toString() {
    return 'Customer{id: $_id, name: $_name, phone: $_phoneNumber}';
  }
}

class Order {
  final String _orderId;
  final String _tableId;
  final List<OrderedItem> _orderedItems;
  final DateTime _orderDate;
  OrderStatus _status;

  Order({
    required String orderId,
    required String tableId,
    required List<OrderedItem> orderedItems,
  })  : _orderId = orderId,
        _tableId = tableId,
        _orderedItems = List.from(orderedItems), 
        _orderDate = DateTime.now(),
        _status = OrderStatus.Pending;

  String get orderId => _orderId;
  String get tableId => _tableId;
  OrderStatus get orderStatus => _status;
  List<OrderedItem> get orderedItems => List.unmodifiable(_orderedItems);
  DateTime get orderDate => _orderDate;

  // Calculate total amount
  double get totalAmount {
    return orderedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void updateStatus(OrderStatus newStatus) {
    _status = newStatus;
  }

  @override
  String toString() {
    return 'Order{orderId: $_orderId, '
        'orderedItems: $_orderedItems, totalAmount: $totalAmount, orderDate: $_orderDate}';
  }
}

class Table {
  final String _tableId;
  final int _seats;
  final Map<DateTime, List<Reservation>> reservations;

  Table({
    required String tableId,
    required int seats,
  })  : _tableId = tableId,
        _seats = seats,
        reservations = {};


  String get tableId => _tableId;
  int get seats => _seats;

  void reserve(DateTime reservationTime, Reservation reservation, Duration duration) {
    DateTime endTime = reservationTime.add(duration); 

    for (var existingReservation in reservations.keys) {
      DateTime existingEndTime = existingReservation
          .add(duration); 

      if ((reservationTime.isBefore(existingEndTime) &&
              endTime.isAfter(existingReservation)) ||
          (existingReservation.isBefore(endTime) &&
              existingEndTime.isAfter(reservationTime))) {
        throw Exception(
            'Reservation time overlaps with an existing reservation.');
      }
    }

    if (reservations.containsKey(reservationTime)) {
      reservations[reservationTime]!.add(reservation);
    } else {
      reservations[reservationTime] = [reservation];
    }
  }

  bool isAvailable(DateTime reservationTime, int numberOfGuests) {
    if (seats < numberOfGuests) return false; 
    return !reservations.containsKey(
        reservationTime); 
  }

  @override
  String toString() {
    return 'Table{tableId: $_tableId, seats: $_seats}';

  }
  
  void releaseReservation(String reservationId) {
    // Create a list to hold keys that need to be removed
    List<DateTime> keysToRemove = [];

    for (var entry in reservations.entries) {
      List<Reservation> reservationList =
          entry.value; // Get the list of reservations for this date

      // Remove the reservation by ID
      reservationList
          .removeWhere((reservation) => reservation.id == reservationId);

      // Check if the list is empty after removal
      if (reservationList.isEmpty) {
        keysToRemove.add(entry.key); // Mark this key for removal
      }
    }

    // Now remove the keys outside the iteration
    for (var key in keysToRemove) {
      reservations.remove(key);
    }
  }

}

class Reservation {
  final String id; 
  final String customerId;
  final String tableId;
  final DateTime reservationTime;
  final int numberOfGuests;
  final String? specialRequest;
  ReservationStatus status;

  Reservation({
    required this.id,
    required this.customerId,
    required this.tableId,
    required this.reservationTime,
    required this.numberOfGuests,
    this.specialRequest,
    this.status = ReservationStatus.pending,
  });

  String get getCustomerId => customerId;
  String get getTableId => tableId;
  DateTime get getReservationTime => reservationTime;
  int get getNumberOfGuests => numberOfGuests;
  String? get getSpecialRequest => specialRequest;
  ReservationStatus get getStatus => status;

  @override
  String toString() {
    return 'Reservation{id: $id, customerId: $customerId, tableId: $tableId, '
           'reservationTime: ${reservationTime.toIso8601String()}, '
           'numberOfGuests: $numberOfGuests, specialRequest: ${specialRequest ?? "None"}, '
           'status: $status}';
  }
}

class RestaurantManagementSystem {
  final Menu _menu;
  final List<Customer> _customers = [];
  final List<Table> _tables = [];
  final List<Order> _orders = [];
  final List<Reservation> _reservations = [];
  final List<Payment> _payments = [];

  RestaurantManagementSystem(): _menu = Menu();

  String generateItemId() {
    return 'M${_menu._items.length + 1}'; 
  }

  String generateOrderId() {
    return 'O${_orders.length + 1}';
  }

  String generateReservationId() {
    return 'R${_reservations.length + 1}'; 
  }

  String generateTableId() {
    return 'T${_tables.length + 1}'; 
  }

  String generateCustomerId() {
    return 'C${_customers.length + 1}';
  }

  String generatePaymentId() {
    return 'P${_payments.length + 1}';
  }

  void addMenuItem(MenuItem item) {
    _menu.addItem(item);
  }

  bool removeMenuItem(String id) {
    return _menu.removeItem(id);
  }

  bool updateReservationStatus(String reservationId, ReservationStatus newStatus) {
    var reservation = _reservations.firstWhere(
      (r) => r.id == reservationId,
      orElse: () => throw Exception(
          'Reservation with ID $reservationId not found.'),
    );

    reservation.status = newStatus;
    print('Reservation $reservationId status updated to $newStatus.');
    return true; 
  }

  void showMenuItems() {
    if (_menu._items.isEmpty) {
      print('The menu is currently empty.');
    } else {
      print('Menu Items:');
      for (int i = 0; i < _menu._items.length; i++) {
        var item = _menu._items[i];
        print('${i + 1}. ${item.name} - \$${item.price} (${item.description})');
      }
    }
  }

  void addCustomer(Customer customer) {
    _customers.add(customer);
  }

  List<Customer> listCustomers() {
    return List.unmodifiable(_customers);
  }

  void addTable(Table table) {
    _tables.add(table);
  }

  void showAllTables() {
    if (_tables.isEmpty) {
      print('No tables found.');
      return;
    }

    print('--- List of Tables ---');
    for (int i = 0; i < _tables.length; i++) {
      var table = _tables[i];
      print('${i + 1}. $table'); // Displaying each table with an index
    }
  }

  void removeTable(String tableId) {
    var table = _tables.firstWhere((t) => t.tableId == tableId,
        orElse: () =>
            throw Exception('Table with ID $tableId not found.'));
    _tables.remove(table);
  }

  void reserveTable({
    required String customerName,
    required String contactNumber,
    required DateTime reservationTime,
    required int numberOfGuests,
    String? specialRequest,
    Duration duration = const Duration(hours: 2)
  }) {
    var _res = null;
    bool tableFound = false;
    String cusId = '';

    try {
      for (int i = 0; i < _tables.length; i++) {
        var t = _tables[i];
        if (t.isAvailable(reservationTime, numberOfGuests)) {
          _res = t.tableId;

          final Customer _cus = Customer(
            id: generateCustomerId(),
            name: customerName,
            phoneNumber: contactNumber,
          );
          cusId = _cus.id;
          addCustomer(_cus);
          tableFound = true;
          Reservation r = Reservation(
              id: generateReservationId(),
              customerId: cusId,
              tableId: _res,
              reservationTime: reservationTime,
              numberOfGuests: numberOfGuests);
          _reservations.add(r);
          t.reserve(reservationTime, r, Duration());
          break;
        }
      }

      if (!tableFound) {
        throw Exception(
            'No available table for $numberOfGuests guests on ${reservationTime.toLocal()}');
      }

      print(
          'Table ${_res} has been reserved for $customerName on ${reservationTime.toLocal()}.');
      print('Contact: $contactNumber, Guests: $numberOfGuests');
      if (specialRequest != null) {
        print('Special Request: $specialRequest');
      }
    }
    catch (e) {
      print('Error during reservation: $e');
    }
  }

  void releaseReservation(String tableId, Reservation reservation) {
    var table = _tables.firstWhere((t) => t.tableId == tableId,
        orElse: () => throw Exception('Table not found.'));
    table.releaseReservation(reservation.id);
  }

  void displayAllReservations() {
    if (_reservations.isEmpty) {
      print('No reservations found.');
      return;
    }

    print('--- List of Reservations ---');
    for (int i = 0; i < _reservations.length; i++) {
      var reservation = _reservations[i];
      print(
          '${i + 1}. $reservation'); // Displaying each reservation with an index
    }
  }

  List<Table> listTables() {
    return List.unmodifiable(_tables);
  }

  void displayTables() {
    print('Tables:');
    for (int i = 0; i < _tables.length; i++) {
      var table = _tables[i];
      print(
          '${i + 1}. Table ID: ${table.tableId}, Seats: ${table.seats}');
    }
  }

  String createOrder(String tableId, Map<String, int> menuItemQuantities) {
    List<OrderedItem> orderedItems = [];

    // Look up each MenuItem by ID and add it to orderedItems
    menuItemQuantities.forEach((id, quantity) {
      MenuItem item = _menu._items.firstWhere(
        (menuItem) => menuItem.id == id,
        orElse: () => throw Exception('MenuItem ID $id not found.'),
      );
      orderedItems.add(OrderedItem(menuItem: item, quantity: quantity));
    });

    String orderId = 'O${_orders.length + 1}'; 
    Order newOrder = Order(
      orderId: orderId,
      tableId: tableId,
      orderedItems: orderedItems,
    );

    _orders.add(newOrder);
    print('Order created successfully!');
    print('Order ID: ${newOrder.orderId}, Table ID: ${newOrder.tableId}, Status: ${newOrder.orderStatus}');
    print('Ordered Items:');

    for (var item in newOrder.orderedItems) {
      print('- ${item.menuItem.name}: ${item.quantity} x \$${item.menuItem.price.toStringAsFixed(2)}');
    }

    print('Total Price: \$${newOrder.totalAmount.toStringAsFixed(2)}\n');

    return orderId;
  }

  List<Order> listOrders() {
    return List.unmodifiable(_orders);
  }

  void displayAllOrders() {
    if (_orders.isEmpty) {
      print('No orders have been placed yet.');
      return;
    }

    print('Current Orders:');
    for (int i = 0; i < _orders.length; i++) {
      var order = _orders[i];
      print('Order ${i + 1}:');
      print(
          'Order ID: ${order.orderId}, Table ID: ${order.tableId}, Status: ${order.orderStatus}');
      print('Ordered Items:');

      for (var item in order.orderedItems) {
        print('- ${item.menuItem.name}: ${item.quantity} x \$${item.menuItem.price.toStringAsFixed(2)}');
      }

      print('Total Price: \$${order.totalAmount.toStringAsFixed(2)}\n');
    }
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    var order = _orders.firstWhere(
      (o) => o.orderId == orderId,
      orElse: () => throw Exception('Order with ID $orderId not found.'),
    );

    // Update the order status
    order.updateStatus(newStatus);
    print('Order $orderId status updated to $newStatus.');
  }

  PaymentMethod getPaymentMethod() {
    while (true) {
      print('Enter payment method (ABA, ACLEDA, CASH):');
      String? input = stdin.readLineSync();

      if (input != null) {
        try {
          return PaymentMethod.values.firstWhere((method) =>
              method.toString().split('.').last.toUpperCase() ==
              input.toUpperCase());
        } catch (e) {
          print('Invalid payment method. Please try again.');
        }
      } else {
        print('Input cannot be null. Please try again.');
      }
    }
  }

  void addPayment(String tableId, String reservationId, String orderId, double amount,
      String payMethod) {
    var lastOrder = _orders.reversed.firstWhere(
      (o) => o.tableId == tableId,
      orElse: () => throw Exception('No orders found for table ID $tableId.'),
    );

    double totalAmount = lastOrder.totalAmount;

    Reservation? reservation = _reservations
        .firstWhere((r) => r.id == reservationId, orElse: () =>
        throw Exception('No reservation found for table ID $tableId.') );
    for (var table in _tables) {
      if (table.tableId == reservation.tableId) {
        table.releaseReservation(reservationId);
        break;
      }
    }
    print('Reservation with ID $reservationId has been released.');
    
    PaymentMethod method = PaymentMethod.CASH;
    switch(payMethod.toLowerCase()) {
      case 'aba':
        method = PaymentMethod.ABA;
        break;
      case 'acleda':
        method = PaymentMethod.ACLEDA;
        break;
      default :
        method = PaymentMethod.CASH;
        break;
    }

    var payment = Payment(
      paymentId: generatePaymentId(),
      orderId: orderId,
      amount: amount,
      paymentMethod: method,
    );

    payment.processPayment(totalAmount);
    _payments.add(payment);
    print('Order ID: ${lastOrder.orderId}, Table ID: ${lastOrder.tableId}}');
    print('Ordered Items:');
    for (var item in lastOrder.orderedItems) {
      print(
          '- ${item.menuItem.name}: ${item.quantity} x \$${item.menuItem.price.toStringAsFixed(2)}');
    }
    print('Total Price: \$${lastOrder.totalAmount.toStringAsFixed(2)}\n');
    
    print('Payment ${payment.paymentId} added successfully. Change to return: ${payment.change}');
  }

  List<Payment> listPayments() {
    return List.unmodifiable(_payments);
  }
  
  void showAllPayments() {
    if (_payments.isEmpty) {
      print('No payments found.');
      return;
    }

    print('--- List of Payments ---');
    for (var payment in _payments) {
      print(payment);
    }
  }
}

void displayMainMenu() {
  print('--- Restaurant Management System ---');
  print('1. Manage Menu');
  print('2. Manage Orders');
  print('3. Manage Reservations');
  print('4. Manage Payments');
  print('5. Manage Tables');
  print('q. Exit');
  print('Please choose an option:');
}

void displayManageMenuItems(RestaurantManagementSystem restaurant) {
  while (true) {
    print('--- Manage Menu Items ---');
    print('1. Add Menu Item');
    print('2. Show Menu Items');
    print('3. Remove Menu Item');
    print('4. Back to Main Menu ');
    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        // Add Menu Item
        String id = restaurant.generateItemId(); // Auto-generated item ID
        print('Generated item ID: $id');

        // Get item name
        String? name;
        while (name == null || name.isEmpty) {
          print('Enter item name (cannot be empty):');
          name = stdin.readLineSync();
        }

        // Get item price
        double? price;
        while (price == null) {
          print('Enter item price (must be a number):');
          String? priceInput = stdin.readLineSync();
          price = double.tryParse(priceInput ?? '');
          if (price == null) {
            print('Invalid input. Please enter a valid number for the price.');
          }
        }

        // Get item type
        itemType? type;
        while (type == null) {
          print('Enter item type (Appetizer/MainCourse/Dessert/Beverage):');
          String? typeInput = stdin.readLineSync();
          if (typeInput != null) {
            switch (typeInput.toLowerCase()) {
              case 'appetizer':
                type = itemType.APPETIZER;
                break;
              case 'maincourse':
                type = itemType.MAINCOURSE;
                break;
              case 'dessert':
                type = itemType.DESSERT;
                break;
              case 'beverage':
                type = itemType.BEVERAGE;
                break;
              default:
                print(
                    'Invalid item type. Please enter "Appetizer", "MainCourse", "Dessert", or "Beverage".');
            }
          }
        }
        restaurant.addMenuItem(MenuItem(id: id, name: name, price: price, type: type));
        print('Menu item added successfully.');
        break;
      case '2':
        restaurant.showMenuItems();
        break;

      case '3':
        String? idToRemove;
        while (idToRemove == null || idToRemove.isEmpty) {
          print('Enter the ID of the item to remove (cannot be empty):');
          idToRemove = stdin.readLineSync();
          if (idToRemove == null || idToRemove.isEmpty) {
            print('ID cannot be null or empty. Please try again.');
          }
        }

        if (restaurant.removeMenuItem(idToRemove)) {
          print('Menu item with ID $idToRemove has been removed successfully.');
        } else {
          print('Menu item with ID $idToRemove not found.');
        }
        break; 
      case '4':
        return;
      default:
        print('Invalid option. Please try again.');
    }
  }
}

void displayManageReservations(RestaurantManagementSystem restaurant) {
  while (true) {
    print('--- Manage Reservations ---');
    print('1. Add Reservation');
    print('2. Show Reservations');
    print('3. Update Reservation');
    print('4. Back to Main Menu');
    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        String? customerName;
        String? contactNumber;
        DateTime? reservationTime;
        int? numberOfGuests;

        // Validate customer name
        while (customerName == null || customerName.isEmpty) {
          print('Enter customer name:');
          customerName = stdin.readLineSync();
          if (customerName == null || customerName.isEmpty) {
            print('Customer name cannot be null or empty. Please try again.');
          }
        }

        // Validate contact number
        while (contactNumber == null || contactNumber.isEmpty) {
          print('Enter contact number:');
          contactNumber = stdin.readLineSync();
          if (contactNumber == null || contactNumber.isEmpty) {
            print('Contact number cannot be null or empty. Please try again.');
          }
        }

        // Validate reservation time
        while (reservationTime == null) {
          print('Enter reservation time (YYYY-MM-DD HH:MM):');
          String? dateTimeInput = stdin.readLineSync();
          try {
            reservationTime = DateTime.parse(dateTimeInput!);
          } catch (e) {
            print('Invalid date format. Please use YYYY-MM-DD HH:MM.');
          }
        }

        // Validate number of guests
        while (numberOfGuests == null) {
          print('Enter number of guests:');
          String? guestsInput = stdin.readLineSync();
          numberOfGuests = int.tryParse(guestsInput ?? '');
          if (numberOfGuests == null || numberOfGuests <= 0) {
            print('Invalid input. Please enter a valid number of guests.');
          }
        }

        // Call the reserveTable method
        restaurant.reserveTable(
          customerName: customerName,
          contactNumber: contactNumber,
          reservationTime: reservationTime,
          numberOfGuests: numberOfGuests,
        );
        break;

      case '2':
        restaurant.displayAllReservations();
        break;

      case '3':
        print('--- Update Reservation Status ---');

        // Get reservation ID
        String? reservationId;
        while (reservationId == null || reservationId.isEmpty) {
          print('Enter reservation ID:');
          reservationId = stdin.readLineSync();
          if (reservationId == null || reservationId.isEmpty) {
            print('Reservation ID cannot be null or empty. Please try again.');
          }
        }

        // Get new status
        ReservationStatus? newStatus;
        while (newStatus == null) {
          print('Enter new status (pending, confirmed, canceled, completed):');
          String? statusInput = stdin.readLineSync();
          if (statusInput != null) {
            switch (statusInput.toLowerCase()) {
              case 'pending':
                newStatus = ReservationStatus.pending;
                break;
              case 'confirmed':
                newStatus = ReservationStatus.confirmed;
                break;
              case 'canceled':
                newStatus = ReservationStatus.canceled;
                break;
              case 'completed':
                newStatus = ReservationStatus.completed;
                break;
              default:
                print(
                    'Invalid status. Please enter one of the following: pending, confirmed, canceled, completed.');
                break;
            }
          } else {
            print('Status cannot be null. Please try again.');
          }
        }

        try {
          restaurant.updateReservationStatus(reservationId, newStatus);
        } catch (e) {
          print(e); 
        }

        break;
      case '4':
      return;

      default:
        print('Invalid option. Please try again.');
    }
  }
}

void displayManageOrders(RestaurantManagementSystem restaurant) {
  while (true) {
    print('--- Manage Orders ---');
    print('1. Create Order');
    print('2. Display All Orders');
    print('3. Update Order Status');
    print('4. Back to Main Menu');
    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':

        print('Enter table ID:');
        String? tableId = stdin.readLineSync();
        if (tableId == null || tableId.isEmpty) {
          print('Table ID cannot be null or empty.');
          break;
        }

        Map<String, int> orderItems = {};
        while (true) {
          print('Enter MenuItem ID to order (or "done" to finish):');
          String? itemId = stdin.readLineSync();

          if (itemId?.toLowerCase() == 'done') {
            break;
          }

          print('Enter quantity:');
          int? quantity = int.tryParse(stdin.readLineSync() ?? '');

          if (quantity != null && quantity > 0) {
            orderItems[itemId!] = quantity;
          } else {
            print('Invalid quantity. Please try again.');
          }
        }

        if (orderItems.isNotEmpty) {
          restaurant.createOrder(tableId, orderItems);
        } else {
          print('No items selected for the order.');
        }
        break;

      case '2':
        restaurant.displayAllOrders();
        break;

      case '3':
        print('Enter Order ID to update status:');
        String? orderId = stdin.readLineSync();
        if (orderId == null || orderId.isEmpty) {
          print('Order ID cannot be null or empty.');
          break;
        }

        OrderStatus? newStatus;
        while (newStatus == null) {
          print('Enter new status (pending, completed, canceled):');
          String? statusInput = stdin.readLineSync();
          if (statusInput != null && statusInput.isNotEmpty) {
            if (statusInput.toLowerCase() == 'pending'){
              newStatus = OrderStatus.Pending;
            }
            else if(statusInput.toLowerCase() == 'completed') {
              newStatus = OrderStatus.Completed;
            }
            else if(statusInput.toLowerCase() == 'canceled') {
              newStatus = OrderStatus.Canceled;
            }
            else {
              print(
                  'Invalid status. Please enter one of the following: pending, completed, canceled.');
            }
          } else {
            print('Status cannot be null or empty. Please try again.');
          }
        }

        try {
          restaurant.updateOrderStatus(orderId, newStatus);
          print('Order status updated successfully.');
        } catch (e) {
          print(e); 
        }
        break;

      case '4':
        return; 

      default:
        print('Invalid option. Please try again.');
    }
  }
}

void displayManageTables(RestaurantManagementSystem restaurant) {
  while (true) {
    print('--- Manage Tables ---');
    print('1. Add Table');
    print('2. Display All Tables');
    print('3. Remove Table');
    print('4. Back to Main Menu');
    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':
        print('Enter table ID:');
        String? tableId = stdin.readLineSync();
        if (tableId == null || tableId.isEmpty) {
          print('Table ID cannot be null or empty.');
          break;
        }

        print('Enter seats:');
        int? seats = int.tryParse(stdin.readLineSync() ?? '');
        if (seats == null || seats <= 0) {
          print('Invalid seats. Please enter a positive number.');
          break;
        }
        restaurant.addTable(Table(tableId: tableId, seats: seats));
        print('Table $tableId added successfully.');
        break;

      case '2':
        restaurant.showAllTables();
        break;

      case '3':
        print('Enter table ID to remove:');
        String? removeTableId = stdin.readLineSync();
        if (removeTableId == null || removeTableId.isEmpty) {
          print('Table ID cannot be null or empty.');
          break;
        }

        try {
          restaurant.removeTable(removeTableId);
          print('Table $removeTableId removed successfully.');
        } catch (e) {
          print(e); 
        }
        break;

      case '4':
        return; 

      default:
        print('Invalid option. Please try again.');
    }
  }
}

void displayManagePayments(RestaurantManagementSystem restaurant) {
  while (true) {
    print('--- Manage Payments ---');
    print('1. Add Payment');
    print('2. Display All Payments');
    print('3. Back to Main Menu');
    String? choice = stdin.readLineSync();

    switch (choice) {
      case '1':

        print('Enter table ID for the Payment:');
        String? tableId = stdin.readLineSync();
        if (tableId == null || tableId.isEmpty) {
          print('table ID cannot be null or empty.');
          break;
        }

        print('Enter reservation ID for the Payment:');
        String? reservationId = stdin.readLineSync();
        if (reservationId == null || reservationId.isEmpty) {
          print('reservation ID cannot be null or empty.');
          break;
        }


        print('Enter order ID for the Payment:');
        String? orderId = stdin.readLineSync();
        if (orderId == null || orderId.isEmpty) {
          print('order ID cannot be null or empty.');
          break;
        }

        print('Enter amount:');
        double? amount = double.tryParse(stdin.readLineSync() ?? '');
        if (amount == null || amount <= 0) {
          print('Invalid amount. Please enter a positive number.');
          break;
        }

        // Add the payment
        restaurant.addPayment(tableId, reservationId, orderId, amount, restaurant.getPaymentMethod().toString());
        break;

      case '2':
        // Display All Payments
        restaurant.showAllPayments();
        break;

      case '3':
        return; // Back to Main Menu

      default:
        print('Invalid option. Please try again.');
    }
  }
}

void runRestaurantManagementSystem() {
  var restaurant = RestaurantManagementSystem();

  restaurant.addMenuItem(MenuItem(
    id: 'M1',
    name: 'Margherita Pizza',
    price: 10.99,
    description: 'Classic pizza with tomato sauce and mozzarella cheese.',
    type: itemType.MAINCOURSE,
  ));

  restaurant.addMenuItem(MenuItem(
    id: 'M2',
    name: 'Caesar Salad',
    price: 7.49,
    description:
        'Fresh romaine lettuce with Caesar dressing, croutons, and parmesan.',
    type: itemType.APPETIZER,
  ));

  restaurant.addMenuItem(MenuItem(
    id: 'M3',
    name: 'Chocolate Cake',
    price: 5.99,
    description: 'Rich chocolate cake with a creamy frosting.',
    type: itemType.DESSERT,
  ));

  restaurant.addMenuItem(MenuItem(
    id: 'M4',
    name: 'Iced Tea',
    price: 2.99,
    description: 'Refreshing iced tea served with lemon.',
    type: itemType.BEVERAGE,
  ));

  restaurant.addTable(Table(tableId: 'T1', seats: 2));
  restaurant.addTable(Table(tableId: 'T2', seats: 2));
  restaurant.addTable(Table(tableId: 'T3', seats: 6));
  restaurant.addTable(Table(tableId: 'T4', seats: 8));
  restaurant.addTable(Table(tableId: 'T5', seats: 4));

  while (true) {
    displayMainMenu();
    String? choice = stdin.readLineSync();
    switch (choice) {
      case '1':
        displayManageMenuItems(restaurant);
        break;
      case '2':
        displayManageOrders(restaurant);
        break;
      case '3':
        displayManageReservations(restaurant);
        break;
      case '4':
        displayManagePayments(restaurant);
        break;
      case '5':
        displayManageTables(restaurant);
      case 'q':
        print('Exiting the system.');
        return;
      default:
        print('Invalid option. Please try again.');
    }
  }
}
void main() {
  runRestaurantManagementSystem();
}