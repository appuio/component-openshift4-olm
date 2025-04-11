/**
 * \file olm.libsonnet
 * \brief Helpers to create CatalogSource CRs.
 */

local kap = import 'lib/kapitan.libjsonnet';
local groupVersion = 'operators.coreos.com/v1alpha1';

/**
  * \brief Helper to create CatalogSource objects.
  *
  * \arg The name of the JsonnetLibrary.
  * \arg The namespace of the ManagedResource.
  * \return A JsonnetLibrary object.
  */
local catalogSource(name) = {
  apiVersion: groupVersion,
  kind: 'CatalogSource',
  metadata: {
    labels: {
      'app.kubernetes.io/name': name,
    },
    name: name,
    namespace: kap.inventory().parameters.openshift4_olm.namespace,
  },
};

{
  catalogSource: catalogSource,
}
