import 'src/Router/Router.dart';

main(){
  Router router = new Router("/Routes/");
  router.launch("127.0.0.1", 8000);
}