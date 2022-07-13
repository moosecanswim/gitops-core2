// Grey Matter configuration for Edge

package greymatter

let Name = "multimesh-bridge"
let EgressToRedisName = "\(Name)_egress_to_redis"
let EgressToCatalogName = "\(Name)_egress_to_catalog"
let EgressToControlName = "\(Name)_egress_to_control"

multimesh_bridge_config: [
	#domain & {
		domain_key:   Name
		_force_https: defaults.multimesh_bridge.enable_tls
	},
	#listener & {
		listener_key:                Name
		_gm_observables_topic:       Name
		_is_ingress:                 true
		_enable_rbac:                defaults.multimesh_bridge._enable_rbac
	},
	// This cluster must exist (though it never receives traffic)
	// so that Catalog will be able to look-up edge instances
	#cluster & {cluster_key: Name},

	// egress->redis
	#domain & {domain_key: EgressToRedisName, port: defaults.ports.redis_ingress},
	#cluster & {
		cluster_key:  EgressToRedisName
		name:         defaults.redis_cluster_name
		_spire_self:  Name
		_spire_other: defaults.redis_cluster_name
	},
	#route & {route_key: EgressToRedisName},
	#listener & {
		listener_key:  EgressToRedisName
		ip:            "127.0.0.1" // egress listeners are local-only
		port:          defaults.ports.redis_ingress
		_tcp_upstream: defaults.redis_cluster_name
        _enable_rbac:  defaults.multimesh_bridge._enable_rbac
	},

	// Connection to the Catalog from Control-EDGE
	#cluster & {
		cluster_key: EgressToCatalogName
		name:        "catalog"
	},

	#route & {
		domain_key: Name
		route_key:  EgressToCatalogName
		route_match: {
			path: "/services/catalog/"
		}
		redirects: [
			{
				from:          "^/services/catalog$"
				to:            route_match.path
				redirect_type: "permanent"
			},
		]
		prefix_rewrite: "/"
	},

	// egress->control
	#domain & {domain_key: EgressToControlName, port: defaults.ports.control_ingress},
	#cluster & {
		cluster_key:    EgressToControlName
		name:           "control"
		_upstream_host: defaults.xds_host
		_upstream_port: 50001
		_spire_self:    Name
		_spire_other:   "controlensemble"
		http2_protocol_options: {
			allow_connect: true
		}
	},

	#route & {route_key: EgressToControlName},

	#listener & {
		listener_key: EgressToControlName
		ip:           "0.0.0.0" // egress listeners are local-only
		port:         defaults.ports.control_ingress
		_enable_rbac: defaults.multimesh_bridge._enable_rbac
		http2_protocol_options: {
			allow_connect: true
		}
	},

	#proxy & {
		proxy_key: Name
		domain_keys: [Name, EgressToRedisName]
		listener_keys: [Name, EgressToRedisName]
	},
]
