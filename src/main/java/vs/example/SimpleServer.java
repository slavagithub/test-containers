package vs.example;

import static spark.Spark.get;

public class SimpleServer {
    private static String URI = "/available";
    public static void main(String[] args) {
        startServer();
    }

    private static void startServer() {
        get(URI, (req, res) -> "true");

    }
}
