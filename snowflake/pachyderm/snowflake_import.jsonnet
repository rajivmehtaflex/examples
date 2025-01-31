local newPipeline(name, input, transform) = {
	pipeline: {
		name: name,
	},
	transform: transform,
	input: input,	
};
local pachtf(args, secretName="") = {
	image: "pachyderm/pachtf:2.2.0-0aa162454babe54bceb3a7376e37473349fe14ae",
	cmd: ["/app/pachtf"] + args,
	secrets: if secretName != "" then
		[
			{
				name: secretName,
				env_var: "PACHYDERM_SQL_PASSWORD",
				key: "PACHYDERM_SQL_PASSWORD",
			}
		]
	else
		null
	,
};

function (name, url, query, format, cronSpec, secretName)
	local queryPipelineName = name + "_queries";
	[
	newPipeline(
		name=queryPipelineName,
	 	input={
			cron: {
				name: "in",
				spec: cronSpec,
				overwrite: true,
			}
	  },
	  transform=pachtf(["sql-gen-queries", query]),
	),
	newPipeline(
		name=name,
		input={
			pfs: {
				name: "in",
				repo: queryPipelineName,
				glob: "/*",
			},
		},
		transform=pachtf(["sql-ingest", url, format], secretName),
	)
	]
