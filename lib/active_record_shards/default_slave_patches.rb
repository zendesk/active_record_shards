ActiveRecordShards::Deprecation.warn('`DefaultSlavePatches` is deprecated, please use `DefaultReplicaPatches`.')

module ActiveRecordShards
  DefaultSlavePatches = DefaultReplicaPatches
end
