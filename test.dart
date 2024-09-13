const logMethodCall = "LogMethodCall()";

class MyService {
  @logMethodCall
  void fetchData() {
    print('Fetching data...');
  }

  @logMethodCall
  void sendData() {
    print('Sending data...');
  }
}

void main(List<String> args) {
  final myService = MyService();
  myService.fetchData();
  myService.sendData();
}
