public class App {
    public static void main(String[] args) {
        System.out.println("App started - debugger is listening on port 5005");
        System.out.println("Connect IntelliJ debugger now...");
        
        try {
            while (true) {
                Thread.sleep(5000);
                System.out.println("App is running...");
            }
        } catch (InterruptedException e) {
            System.err.println("App interrupted: " + e.getMessage());
        }
    }
}
