/// Pure ownership rules for asynchronous Firebase Installation ID callbacks.
class FcmRegistrationOwnership {
  final Map<String, List<String>> _pendingOwnersByFid = {};

  void queueUnregistration(String fid, String ownerId) {
    if (fid.isEmpty || ownerId.isEmpty) return;
    (_pendingOwnersByFid[fid] ??= <String>[]).add(ownerId);
  }

  String? takeUnregistrationOwner(String fid, String? fallbackOwnerId) {
    final owners = _pendingOwnersByFid[fid];
    if (owners == null || owners.isEmpty) return fallbackOwnerId;
    final ownerId = owners.removeAt(0);
    if (owners.isEmpty) _pendingOwnersByFid.remove(fid);
    return ownerId;
  }

  void removeQueuedUnregistration(String fid, String ownerId) {
    final owners = _pendingOwnersByFid[fid];
    owners?.remove(ownerId);
    if (owners != null && owners.isEmpty) {
      _pendingOwnersByFid.remove(fid);
    }
  }

  bool shouldClearTrackedRegistration({
    required String? trackedFid,
    required String? trackedOwnerId,
    required String callbackFid,
    required String? callbackOwnerId,
  }) {
    return trackedFid == callbackFid &&
        (trackedOwnerId == null || trackedOwnerId == callbackOwnerId);
  }
}
