package app.coronawarn.server.services.submission.controller;

public class SubmissionHeaders {

  private final String tan;
  private final boolean traveler;
  private final boolean sharedConsent;

  private SubmissionHeaders(String tan, boolean traveler, boolean sharedConsent) {
    this.tan = tan;
    this.traveler = traveler;
    this.sharedConsent = sharedConsent;
  }

  public static SubmissionHeaders of(String tan, boolean traveler, boolean sharedConsent) {
    return new SubmissionHeaders(tan, traveler, sharedConsent);
  }

  public String getTan() {
    return tan;
  }

  public boolean isTraveler() {
    return traveler;
  }

  public boolean isSharedConsent() {
    return sharedConsent;
  }
}
