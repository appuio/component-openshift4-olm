// main template for openshift4-olm
local com = import 'lib/commodore.libjsonnet';
local espejote = import 'lib/espejote.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local olm = import 'lib/openshift4-olm.libsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.openshift4_olm;

local patchDisableDefaultSources = [
  espejote.managedResource('disable-default-sources', 'openshift-marketplace') {
    spec: {
      triggers: [
        {
          name: 'interval',
          interval: '10s',
        },
        {
          name: 'operatorhub',
          watchResource: {
            apiVersion: 'config.openshift.io/v1',
            kind: 'OperatorHub',
            name: 'cluster',
            namespace: 'default',
          },
        },
      ],
      serviceAccountRef: {
        name: 'disable-default-sources',
      },
      template: |||
        local esp = import 'espejote.libsonnet';
        if esp.triggerName == 'operatorhub' then esp.triggerData().resource {
          spec: {
            disableAllDefaultSources: true,
          }
        }
      |||,
    },
  },
  {
    apiVersion: 'v1',
    kind: 'ServiceAccount',
    metadata: {
      labels: {
        'app.kubernetes.io/name': 'disable-default-sources',
        'managedresource.espejote.io/name': 'disable-default-sources',
      },
      name: 'disable-default-sources',
      namespace: params.namespace,
    },
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'Role',
    metadata: {
      labels: {
        'app.kubernetes.io/name': 'disable-default-sources',
      },
      name: 'olm:disable-default-sources',
      namespace: 'default',
    },
    rules: [
      {
        apiGroups: [ 'config.openshift.io/v1' ],
        resources: [ 'OperatorHub' ],
        verbs: [ '*' ],
      },
    ],
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'RoleBinding',
    metadata: {
      labels: {
        'app.kubernetes.io/name': 'disable-default-sources',
      },
      name: 'olm:disable-default-sources',
      namespace: 'default',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'Role',
      name: 'olm:disable-default-sources',
    },
    subjects: [
      {
        kind: 'ServiceAccount',
        name: 'disable-default-sources',
        namespace: params.namespace,
      },
    ],
  },
];

local catalogSources = com.generateResources(params.catalogSources, olm.catalogSource);

// Define outputs below
{
  [if std.length(catalogSources) > 0 then '10_catalog_sources']: catalogSources,
  [if params.disableAllDefaultSources then '10_disable_default_sources']: patchDisableDefaultSources,
}
