package greymatter

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

let Name = "control-edge"
control_edge: [
	appsv1.#Deployment & {
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      Name
			namespace: mesh.spec.install_namespace
		}
		spec: {
			selector: {
				matchLabels: {"greymatter.io/cluster": Name}
			}
			template: {
				metadata: {
					labels: {"greymatter.io/cluster": Name}
				}
				spec:{
					containers: [
						#sidecar_container_block & {
							_Name: Name
							_volume_mounts: [
								if defaults.bridge.enable_tls == true {
									{
										name:      "tls-certs"
										mountPath: "/etc/proxy/tls/sidecar"
									}
								},
							],
							ports: [
								{
									name:          "proxy"
									containerPort: defaults.ports.default_ingress
									},
								{
									name: "control-port"
									containerPort: 50000
								}
							]
						},
					]
					volumes: #sidecar_volumes + [
							if defaults.bridge.enable_tls == true {
							{
								name: "tls-certs"
								secret: {defaultMode: 420, secretName: defaults.bridge.tls_secret_name}
							}
						},
					]
					imagePullSecrets: [{name: defaults.image_pull_secret_name}]
				}
			}
		}
	},

	corev1.#Service & {
		apiVersion: "v1"
		kind:       "Service"
		metadata: {
			name:      Name
			namespace: mesh.spec.install_namespace
		}
		spec: {
			selector: "greymatter.io/cluster": Name
			type: "LoadBalancer"
			ports: [{
				name:       "greymatter"
				port:       10808
				targetPort: 10808
			},
			{
				name: "control"
				port: 50000
				targetPort: 50000
			}
			]
		}
	},
]
