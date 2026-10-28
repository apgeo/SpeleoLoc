import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';

/// The optional parts of the sync contract a caver is told about, each with
/// the capabilities feature that announces it.
enum SilexgisServedPart {
  documents(SilexgisContract.featureDocuments),
  documentUpload(SilexgisContract.featureDocumentUpload),
  trips(SilexgisContract.featureTrips),
  rasters(SilexgisContract.featureRasters),
  reviews(SilexgisContract.featureReviews),
  people(SilexgisContract.featurePeople);

  const SilexgisServedPart(this.feature);
  final String feature;

  /// Whether [profile]'s installation offered this part on the last run, or
  /// null when no run has reached it yet.
  bool? servedBy(SilexgisProfile profile) =>
      profile.servedFeatures?.contains(feature);
}

/// What this device does with sending photos and documents, by its settings.
enum SilexgisFileSending {
  /// Switched off on this device: files stay here.
  off,

  /// Over Wi-Fi; away from it, the caver is asked.
  wifiOrAsk,

  /// Over Wi-Fi only; away from it, files wait.
  wifiOnly,

  /// Over any network.
  anyNetwork;

  static SilexgisFileSending of(SilexgisProfile profile) {
    if (!profile.sendsFiles) return off;
    if (!profile.filesOnlyOverWifi) return anyNetwork;
    return profile.asksBeforeMobileData ? wifiOrAsk : wifiOnly;
  }
}
