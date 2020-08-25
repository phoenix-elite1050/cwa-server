package app.coronawarn.server.services.federation.upload.client;

import app.coronawarn.server.common.federation.client.FederationServerClient;
import app.coronawarn.server.services.federation.upload.payload.UploadPayload;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("!fake-client")
public class ProdFederationUploadClient implements FederationUploadClient {

  private final FederationServerClient federationServerClient;

  public ProdFederationUploadClient(FederationServerClient federationServerClient) {
    this.federationServerClient = federationServerClient;
  }

  @Override
  public void postBatchUpload(UploadPayload uploadPayload) {
    federationServerClient.postBatchUpload(
        uploadPayload.getBatch().toByteArray(),
        uploadPayload.getBatchTag(),
        uploadPayload.getBatchSignature());
  }
}
