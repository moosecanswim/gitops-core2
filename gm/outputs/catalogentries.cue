// All Catalog Service entries

package greymatter

import (
	//  "greymatter.io/operator/greymatter-cue/greymatter"
	"strings"
)

// TODO catalog entries could go into each of the other gm/outputs/ files, to keep things near other Grey Matter config

#CatalogService: {
	mesh_id:                   string
	service_id:                string
	name:                      string
	api_endpoint?:             string
	api_spec_endpoint?:        string
	description?:              string
	enable_instance_metrics:   bool | *true
	enable_historical_metrics: bool | *config.enable_historical_metrics

	// missing fields from official cue repo
	business_impact: string // FYI the Go currently uses this field to determine whether this is a catalog service entry
	version?:        string
}

// TODO these should get their own defaults treatment in gm/intermediates.cue

catalog_entries: [
	#CatalogService & {
		name:            "Grey Matter Edge"
		mesh_id:         mesh.metadata.name
		service_id:      defaults.edge.key
		version:         strings.Split(mesh.spec.images.proxy, ":")[1]
		description:     "Handles north/south traffic flowing through the mesh."
		api_endpoint:    "/"
		business_impact: "critical"
	},
	#CatalogService & {
		name:              "Grey Matter Control"
		mesh_id:           mesh.metadata.name
		service_id:        "controlensemble"
		version:           strings.Split(mesh.spec.images.control_api, ":")[1]
		description:       "Manages the configuration of the Grey Matter data plane."
		api_endpoint:      "/services/control-api/"
		business_impact:   "critical"
		api_spec_endpoint: "/services/control-api/"
	},
	#CatalogService & {
		name:              "Grey Matter Catalog"
		mesh_id:           mesh.metadata.name
		service_id:        "catalog"
		version:           strings.Split(mesh.spec.images.catalog, ":")[1]
		description:       "Interfaces with the control plane to expose the current state of the mesh."
		api_endpoint:      "/services/catalog/"
		api_spec_endpoint: "/services/catalog/"
		business_impact:   "high"
	},
	#CatalogService & {
		name:            "Grey Matter Dashboard"
		mesh_id:         mesh.metadata.name
		service_id:      "dashboard"
		version:         strings.Split(mesh.spec.images.dashboard, ":")[1]
		description:     "A user dashboard that paints a high-level picture of the mesh."
		business_impact: "high"
	},
	if config.enable_historical_metrics {
		#CatalogService & {
			name:            "Grey Matter Prometheus"
			mesh_id:         mesh.metadata.name
			service_id:      "prometheus"
			version:         strings.Split(mesh.spec.images.prometheus, ":")[1]
			description:     "Prometheus TSDB for collecting and querying historical metrics."
			business_impact: "high"
			api_endpoint:    "/services/prometheus/api/v1/"
		}
	},
	if config.enable_multimesh_bridge {
		#CatalogService & {
			name:            "Multimesh Bridge"
			mesh_id:         mesh.metadata.name
			service_id:      "multimesh-bridge"
			version:         strings.Split(mesh.spec.images.proxy, ":")[1]
			description:     "Grey Matter Access point for multimesh connections."
			api_endpoint:    "/services/multimesh-bridge"
			business_impact: "critical"
		}
	},
]
