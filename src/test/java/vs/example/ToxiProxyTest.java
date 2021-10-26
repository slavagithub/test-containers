package vs.example;

import org.junit.Rule;
import org.junit.Test;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.Network;
import org.testcontainers.containers.ToxiproxyContainer;
import org.testcontainers.shaded.okhttp3.OkHttpClient;
import org.testcontainers.shaded.okhttp3.Request;
import org.testcontainers.shaded.okhttp3.Response;
import org.testcontainers.utility.DockerImageName;

import java.io.IOException;

import static java.util.concurrent.TimeUnit.SECONDS;
import static org.awaitility.Awaitility.with;
import static org.junit.Assert.assertEquals;

public class ToxiProxyTest {
    @Rule
    public Network network = Network.newNetwork();

    @Rule
    public GenericContainer simpleServer = new GenericContainer("vs:simple-server")
            .withNetwork(network)
            .withExposedPorts(4567);

    @Rule
    public ToxiproxyContainer toxiproxy = new ToxiproxyContainer(DockerImageName.parse("shopify/toxiproxy:2.1.0"))
            .withNetwork(network).withNetworkAliases("toxiproxy");

    @Test
    public void testNetworkOutage() {
        ToxiproxyContainer.ContainerProxy proxy = toxiproxy.getProxy(simpleServer, 4567);
        final String ipAddressViaToxiproxy = proxy.getContainerIpAddress();
        final int portViaToxiproxy = proxy.getProxyPort();

        waitServerAvailable(true, ipAddressViaToxiproxy,  portViaToxiproxy);

        proxy.setConnectionCut(true);
        waitServerAvailable(false, ipAddressViaToxiproxy,  portViaToxiproxy);

        proxy.setConnectionCut(false);
        waitServerAvailable(true, ipAddressViaToxiproxy,  portViaToxiproxy);

    }

    public void waitServerAvailable(boolean isAvailable, String ip, Integer port) {
        with().pollInterval(1, SECONDS)
              .await()
              .atMost(30, SECONDS)
              .untilAsserted(() -> assertEquals(isAvailable, isTestDataReady(ip, port)));
    }

    private Boolean isTestDataReady(String ip, Integer port) {
        System.out.println("IP: "+ip);
        System.out.println("PORT "+port);
        OkHttpClient httpClient = new OkHttpClient();
        Request request = new Request.Builder()
                .url("http://"+ip+":"+port+"/available")
                .build();

        try (Response response = httpClient.newCall(request).execute()) {
            String body = response.body().string();
            if (body.equals("true")) {
                System.out.println("SEVER AVAILABLE");
                return true;
            }
            return false;
        } catch (IOException ex) {
            System.out.println("SERVER NOT AVAILABLE");
            ex.printStackTrace();
            return false;
        }
    }
}
