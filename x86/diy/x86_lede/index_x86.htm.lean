<%#
 Copyright 2008 Steven Barth <steven@midlink.org>
 Copyright 2008-2011 Jo-Philipp Wich <jow@openwrt.org>
 Licensed to the public under the Apache License 2.0.
-%>

<%
	local fs = require "nixio.fs"
	local util = require "luci.util"
	local stat = require "luci.tools.status"
	local ver = require "luci.version"

	local has_ipv6 = fs.access("/usr/sbin/ip6tables")
	local has_dhcp = fs.access("/etc/config/dhcp")
	local has_wifi = ((fs.stat("/etc/config/wireless", "size") or 0) > 0)

	local sysinfo = luci.util.ubus("system", "info") or { }
	local boardinfo = luci.util.ubus("system", "board") or { }
	local unameinfo = nixio.uname() or { }

	local meminfo = sysinfo.memory or {
		total = 0,
		free = 0,
		buffered = 0,
		shared = 0
	}
	
	local mem_cached = luci.sys.exec("sed -e '/^Cached: /!d; s#Cached: *##; s# kB##g' /proc/meminfo")

	local swapinfo = sysinfo.swap or {
		total = 0,
		free = 0
	}

	local has_dsl = fs.access("/etc/init.d/dsl_control")

	if luci.http.formvalue("status") == "1" then
		local ntm = require "luci.model.network".init()
		local wan = ntm:get_wannet()
		local wan6 = ntm:get_wan6net()

		local conn_count = tonumber(
			fs.readfile("/proc/sys/net/netfilter/nf_conntrack_count") or "") or 0

		local conn_max = tonumber(luci.sys.exec(
			"sysctl -n -e net.nf_conntrack_max net.ipv4.netfilter.ip_conntrack_max"
		):match("%d+")) or 4096

		local cpu_info = luci.sys.exec("cpuinfo")

		local eth_info = luci.sys.exec("ethinfo")

		local user_info = luci.sys.exec("cat /proc/net/arp | grep '0x2' | wc -l") or 0
		
		local run_time = luci.sys.exec("awk '{print int($1/86400)\"天 \"int($1%86400/3600)\"时 \"int($1%86400%3600/60)\"分 \"int($1%60)\"秒\"}' /proc/uptime")

                local cpu_usage = (luci.sys.exec("expr 100 - $(top -n 1 | grep -E '^CPU:' | awk -F '%' '{print$4}' | awk -F ' ' '{print$2}' | awk '{print int($1 + 0.5)}')") or "6") .. "%"

		local rv = {
			cpuusage    = cpu_usage,
			cpuinfo    = cpu_info,
			ethinfo    = eth_info,
			userinfo    = user_info,
			runtime = run_time,
                        uptime     = sysinfo.uptime or 0,
			localtime  = os.date(),
			loadavg    = sysinfo.load or { 0, 0, 0 },
			memory     = meminfo,
			memcached  = mem_cached,
			swap       = swapinfo,
			connmax    = conn_max,
			conncount  = conn_count,
			leases     = stat.dhcp_leases(),
			leases6    = stat.dhcp6_leases(),
			wifinets   = stat.wifi_networks()
		}

		if wan then
			rv.wan = {
				ipaddr  = wan:ipaddr(),
				gwaddr  = wan:gwaddr(),
				netmask = wan:netmask(),
				dns     = wan:dnsaddrs(),
				expires = wan:expires(),
				uptime  = wan:uptime(),
				proto   = wan:proto(),
				ifname  = wan:ifname(),
				link    = wan:adminlink()
			}
		end

		if wan6 then
			rv.wan6 = {
				ip6addr   = wan6:ip6addr(),
				gw6addr   = wan6:gw6addr(),
				dns       = wan6:dns6addrs(),
				ip6prefix = wan6:ip6prefix(),
				uptime    = wan6:uptime(),
				proto     = wan6:proto(),
				ifname    = wan6:ifname(),
				link      = wan6:adminlink()
			}
		end

		if has_dsl then
			local dsl_stat = luci.sys.exec("/etc/init.d/dsl_control lucistat")
			local dsl_func = loadstring(dsl_stat)
			if dsl_func then
				rv.dsl = dsl_func()
			end
		end

		luci.http.prepare_content("application/json")
		luci.http.write_json(rv)

		return
	elseif luci.http.formvalue("hosts") == "1" then
		luci.http.prepare_content("application/json")
		luci.http.write_json(luci.sys.net.host_hints())

		return
	end
-%>

<%+header%>

<script type="text/javascript" src="<%=resource%>/cbi.js?v=git-19.167.54478-71e2af4"></script>
<script type="text/javascript">//<![CDATA[
	function progressbar(v, m)
	{
		var vn = parseInt(v) || 0;
		var mn = parseInt(m) || 100;
		var pc = Math.floor((100 / mn) * vn);

		return String.format(
			'<div style="width:200px; position:relative; border:1px solid #999999">' +
				'<div style="background-color:#CCCCCC; width:%d%%; height:15px">' +
					'<div style="position:absolute; left:0; top:0; text-align:center; width:100%%; color:#000000">' +
						'<small>%s / %s (%d%%)</small>' +
					'</div>' +
				'</div>' +
			'</div>', pc, v, m, pc
		);
	}

	function wifirate(bss, rx) {
		var p = rx ? 'rx_' : 'tx_',
		    s = '%.1f <%:Mbit/s%>, %d<%:MHz%>'
					.format(bss[p+'rate'] / 1000, bss[p+'mhz']),
		    ht = bss[p+'ht'], vht = bss[p+'vht'],
			mhz = bss[p+'mhz'], nss = bss[p+'nss'],
			mcs = bss[p+'mcs'], sgi = bss[p+'short_gi'],
			he = bss[p+'he'], he_gi = bss[p+'he_gi'],
			he_dcm = bss[p+'he_dcm'];

		if (ht || vht) {
			if (vht) s += ', VHT-MCS %d'.format(mcs);
			if (nss) s += ', VHT-NSS %d'.format(nss);
			if (ht)  s += ', MCS %s'.format(mcs);
			if (sgi) s += ', <%:Short GI%>';
		}
		
		if (he) {
			s += ', HE-MCS %d'.format(mcs);
			if (nss) s += ', HE-NSS %d'.format(nss);
			if (he_gi) s += ', HE-GI %d'.format(he_gi);
			if (he_dcm) s += ', HE-DCM %d'.format(he_dcm);
		}

		return s;
	}

	function duid2mac(duid) {
		// DUID-LLT / Ethernet
		if (duid.length === 28 && duid.substr(0, 8) === '00010001')
			return duid.substr(16).replace(/(..)(?=..)/g, '$1:').toUpperCase();

		// DUID-LL / Ethernet
		if (duid.length === 20 && duid.substr(0, 8) === '00030001')
			return duid.substr(8).replace(/(..)(?=..)/g, '$1:').toUpperCase();

		return null;
	}

	var npoll = 1;
	var hosts = <%=luci.http.write_json(luci.sys.net.host_hints())%>;

	function updateHosts() {
		XHR.get('<%=REQUEST_URI%>', { hosts: 1 }, function(x, data) {
			hosts = data;
		});
	}

	var compare = function (prop) {
		return function (obj1, obj2) {
			var val1 = Number(obj1[prop].replaceAll(".",""));
			var val2 = Number(obj2[prop].replaceAll(".",""));
			if (val1 < val2) {
				return -1;
			} else if (val1 > val2) {
				return 1;
			} else {
				return 0;
			}
		}
	};

	XHR.poll(1, '<%=REQUEST_URI%>', { status: 1 },
		function(x, info)
		{
			if (!(npoll++ % 5))
				updateHosts();

			var si = document.getElementById('wan4_i');
			var ss = document.getElementById('wan4_s');
			var ifc = info.wan;

			if (ifc && ifc.ifname && ifc.proto != 'none')
			{
				var s = String.format(
					'<strong><%:Type%>: </strong>%s<br />' +
					'<strong><%:Address%>: </strong>%s<br />' +
					'<strong><%:Netmask%>: </strong>%s<br />' +
					'<strong><%:Gateway%>: </strong>%s<br />',
						ifc.proto,
						(ifc.ipaddr) ? ifc.ipaddr : '0.0.0.0',
						(ifc.netmask && ifc.netmask != ifc.ipaddr) ? ifc.netmask : '255.255.255.255',
						(ifc.gwaddr) ? ifc.gwaddr : '0.0.0.0'
				);

				for (var i = 0; i < ifc.dns.length; i++)
				{
					s += String.format(
						'<strong><%:DNS%> %d: </strong>%s<br />',
						i + 1, ifc.dns[i]
					);
				}

				if (ifc.expires > -1)
				{
					s += String.format(
						'<strong><%:Expires%>: </strong>%t<br />',
						ifc.expires
					);
				}

				if (ifc.uptime > 0)
				{
					s += String.format(
						'<strong><%:Connected%>: </strong>%t<br />',
						ifc.uptime
					);
				}

				ss.innerHTML = String.format('<small>%s</small>', s);
				si.innerHTML = String.format(
					'<img src="<%=resource%>/icons/ethernet.png" />' +
					'<br /><small><a href="%s">%s</a></small>',
						ifc.link, ifc.ifname
				);
			}
			else
			{
				si.innerHTML = '<img src="<%=resource%>/icons/ethernet_disabled.png" /><br /><small>?</small>';
				ss.innerHTML = '<em><%:Not connected%></em>';
			}

			<% if has_ipv6 then %>
			var si6 = document.getElementById('wan6_i');
			var ss6 = document.getElementById('wan6_s');
			var ifc6 = info.wan6;

			if (ifc6 && ifc6.ifname && ifc6.proto != 'none')
			{
				var s = String.format(
					'<strong><%:Type%>: </strong>%s%s<br />',
						ifc6.proto, (ifc6.ip6prefix) ? '-pd' : ''
				);
				
				if (!ifc6.ip6prefix)
				{
					s += String.format(
						'<strong><%:Address%>: </strong>%s<br />',
						(ifc6.ip6addr) ? ifc6.ip6addr : '::'
					);
				}
				else
				{
					s += String.format(
						'<strong><%:Prefix Delegated%>: </strong>%s<br />',
						ifc6.ip6prefix
					);
					if (ifc6.ip6addr)
					{
						s += String.format(
							'<strong><%:Address%>: </strong>%s<br />',
							ifc6.ip6addr
						);
					}
				}

				s += String.format(
					'<strong><%:Gateway%>: </strong>%s<br />',
						(ifc6.gw6addr) ? ifc6.gw6addr : '::'
				);

				for (var i = 0; i < ifc6.dns.length; i++)
				{
					s += String.format(
						'<strong><%:DNS%> %d: </strong>%s<br />',
						i + 1, ifc6.dns[i]
					);
				}

				if (ifc6.uptime > 0)
				{
					s += String.format(
						'<strong><%:Connected%>: </strong>%t<br />',
						ifc6.uptime
					);
				}

				ss6.innerHTML = String.format('<small>%s</small>', s);
				si6.innerHTML = String.format(
					'<img src="<%=resource%>/icons/ethernet.png" />' +
					'<br /><small><a href="%s">%s</a></small>',
						ifc6.link, ifc6.ifname
				);
			}
			else
			{
				si6.innerHTML = '<img src="<%=resource%>/icons/ethernet_disabled.png" /><br /><small>?</small>';
				ss6.innerHTML = '<em><%:Not connected%></em>';
			}
			<% end %>

			<% if has_dsl then %>
				var dsl_i = document.getElementById('dsl_i');
				var dsl_s = document.getElementById('dsl_s');

				var s = String.format(
					'<strong><%:Status%>: </strong>%s<br />' +
					'<strong><%:Line State%>: </strong>%s [0x%x]<br />' +
					'<strong><%:Line Mode%>: </strong>%s<br />' +
					'<strong><%:Annex%>: </strong>%s<br />' +
					'<strong><%:Profile%>: </strong>%s<br />' +
					'<strong><%:Data Rate%>: </strong>%s/s / %s/s<br />' +
					'<strong><%:Max. Attainable Data Rate (ATTNDR)%>: </strong>%s/s / %s/s<br />' +
					'<strong><%:Latency%>: </strong>%s / %s<br />' +
					'<strong><%:Line Attenuation (LATN)%>: </strong>%s dB / %s dB<br />' +
					'<strong><%:Signal Attenuation (SATN)%>: </strong>%s dB / %s dB<br />' +
					'<strong><%:Noise Margin (SNR)%>: </strong>%s dB / %s dB<br />' +
					'<strong><%:Aggregate Transmit Power(ACTATP)%>: </strong>%s dB / %s dB<br />' +
					'<strong><%:Forward Error Correction Seconds (FECS)%>: </strong>%s / %s<br />' +
					'<strong><%:Errored seconds (ES)%>: </strong>%s / %s<br />' +
					'<strong><%:Severely Errored Seconds (SES)%>: </strong>%s / %s<br />' +
					'<strong><%:Loss of Signal Seconds (LOSS)%>: </strong>%s / %s<br />' +
					'<strong><%:Unavailable Seconds (UAS)%>: </strong>%s / %s<br />' +
					'<strong><%:Header Error Code Errors (HEC)%>: </strong>%s / %s<br />' +
					'<strong><%:Non Pre-emtive CRC errors (CRC_P)%>: </strong>%s / %s<br />' +
					'<strong><%:Pre-emtive CRC errors (CRCP_P)%>: </strong>%s / %s<br />' +
					'<strong><%:Line Uptime%>: </strong>%s<br />' +
					'<strong><%:ATU-C System Vendor ID%>: </strong>%s<br />' +
					'<strong><%:Power Management Mode%>: </strong>%s<br />',
						info.dsl.line_state, info.dsl.line_state_detail,
						info.dsl.line_state_num,
						info.dsl.line_mode_s,
						info.dsl.annex_s,
						info.dsl.profile_s,
						info.dsl.data_rate_down_s, info.dsl.data_rate_up_s,
						info.dsl.max_data_rate_down_s, info.dsl.max_data_rate_up_s,
						info.dsl.latency_num_down, info.dsl.latency_num_up,
						info.dsl.line_attenuation_down, info.dsl.line_attenuation_up,
						info.dsl.signal_attenuation_down, info.dsl.signal_attenuation_up,
						info.dsl.noise_margin_down, info.dsl.noise_margin_up,
						info.dsl.actatp_down, info.dsl.actatp_up,
						info.dsl.errors_fec_near, info.dsl.errors_fec_far,
						info.dsl.errors_es_near, info.dsl.errors_es_far,
						info.dsl.errors_ses_near, info.dsl.errors_ses_far,
						info.dsl.errors_loss_near, info.dsl.errors_loss_far,
						info.dsl.errors_uas_near, info.dsl.errors_uas_far,
						info.dsl.errors_hec_near, info.dsl.errors_hec_far,
						info.dsl.errors_crc_p_near, info.dsl.errors_crc_p_far,
						info.dsl.errors_crcp_p_near, info.dsl.errors_crcp_p_far,
						info.dsl.line_uptime_s,
						info.dsl.atuc_vendor_id,
						info.dsl.power_mode_s
				);

				dsl_s.innerHTML = String.format('<small>%s</small>', s);
				dsl_i.innerHTML = String.format(
					'<img src="<%=resource%>/icons/ethernet.png" />' +
					'<br /><small>DSL</small>'
				);
			<% end %>

			<% if has_dhcp then %>
			var ls = document.getElementById('lease_status_table');
			if (ls)
			{
				info.leases = info.leases.sort(compare("ipaddr"));
				/* clear all rows */
				while( ls.rows.length > 1 )
					ls.rows[0].parentNode.deleteRow(1);

				for( var i = 0; i < info.leases.length; i++ )
				{
					var timestr;

					if (info.leases[i].expires === false)
						timestr = '<em><%:unlimited%></em>';
					else if (info.leases[i].expires <= 0)
						timestr = '<em><%:expired%></em>';
					else
						timestr = String.format('%t', info.leases[i].expires);

					var tr = ls.rows[0].parentNode.insertRow(-1);
						tr.className = 'cbi-section-table-row cbi-rowstyle-' + ((i % 2) + 1);

					tr.insertCell(-1).innerHTML = info.leases[i].hostname ? info.leases[i].hostname : '?';
					tr.insertCell(-1).innerHTML = info.leases[i].ipaddr;
					tr.insertCell(-1).innerHTML = info.leases[i].macaddr;
					tr.insertCell(-1).innerHTML = timestr;
				}

				if( ls.rows.length == 1 )
				{
					var tr = ls.rows[0].parentNode.insertRow(-1);
						tr.className = 'cbi-section-table-row';

					var td = tr.insertCell(-1);
						td.colSpan = 4;
						td.innerHTML = '<em><br /><%:There are no active leases.%></em>';
				}
			}

			var ls6 = document.getElementById('lease6_status_table');
			if (ls6 && info.leases6)
			{
				ls6.parentNode.style.display = 'block';

				/* clear all rows */
				while( ls6.rows.length > 1 )
					ls6.rows[0].parentNode.deleteRow(1);

				for( var i = 0; i < info.leases6.length; i++ )
				{
					var timestr;

					if (info.leases6[i].expires === false)
						timestr = '<em><%:unlimited%></em>';
					else if (info.leases6[i].expires <= 0)
						timestr = '<em><%:expired%></em>';
					else
						timestr = String.format('%t', info.leases6[i].expires);

					var tr = ls6.rows[0].parentNode.insertRow(-1);
						tr.className = 'cbi-section-table-row cbi-rowstyle-' + ((i % 2) + 1);

					var host = hosts[duid2mac(info.leases6[i].duid)];
					if (!info.leases6[i].hostname)
						tr.insertCell(-1).innerHTML =
							(host && (host.name || host.ipv4 || host.ipv6))
								? '<div style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space: nowrap">? (%h)</div>'.format(host.name || host.ipv4 || host.ipv6)
								: '?';
					else
						tr.insertCell(-1).innerHTML =
							(host && host.name && info.leases6[i].hostname != host.name)
								? '<div style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space: nowrap">%h (%h)</div>'.format(info.leases6[i].hostname, host.name)
								: info.leases6[i].hostname;

					tr.insertCell(-1).innerHTML = info.leases6[i].ip6addr;
					tr.insertCell(-1).innerHTML = info.leases6[i].duid;
					tr.insertCell(-1).innerHTML = timestr;
				}

				if( ls6.rows.length == 1 )
				{
					var tr = ls6.rows[0].parentNode.insertRow(-1);
						tr.className = 'cbi-section-table-row';

					var td = tr.insertCell(-1);
						td.colSpan = 4;
						td.innerHTML = '<em><br /><%:There are no active leases.%></em>';
				}
			}
			<% end %>

			<% if has_wifi then %>
			var assoclist = [ ];

			var ws = document.getElementById('wifi_status_table');
			if (ws)
			{
				var wsbody = ws.rows[0].parentNode;
				while (ws.rows.length > 0)
					wsbody.deleteRow(0);

				for (var didx = 0; didx < info.wifinets.length; didx++)
				{
					var dev = info.wifinets[didx];

					var tr = wsbody.insertRow(-1);
					var td;

					td = tr.insertCell(-1);
					td.width     = "33%";
					td.innerHTML = dev.name;
					td.style.verticalAlign = "top";

					td = tr.insertCell(-1);

					var s = '';

					for (var nidx = 0; nidx < dev.networks.length; nidx++)
					{
						var net = dev.networks[nidx];
						var is_assoc = (net.bssid != '00:00:00:00:00:00' && net.channel && !net.disabled);

						var icon;
						if (!is_assoc)
							icon = "<%=resource%>/icons/signal-none.png";
						else if (net.quality == 0)
							icon = "<%=resource%>/icons/signal-0.png";
						else if (net.quality < 25)
							icon = "<%=resource%>/icons/signal-0-25.png";
						else if (net.quality < 50)
							icon = "<%=resource%>/icons/signal-25-50.png";
						else if (net.quality < 75)
							icon = "<%=resource%>/icons/signal-50-75.png";
						else
							icon = "<%=resource%>/icons/signal-75-100.png";

						s += String.format(
							'<table><tr><td style="text-align:center; width:32px; padding:3px">' +
								'<img src="%s" title="<%:Signal%>: %d dBm / <%:Noise%>: %d dBm" />' +
								'<br /><small>%d%%</small>' +
							'</td><td style="text-align:left; padding:3px"><small>' +
								'<strong><%:SSID%>:</strong> <a href="%s">%h</a><br />' +
								'<strong><%:Mode%>:</strong> %s<br />' +
								'<strong><%:Channel%>:</strong> %d (%.3f <%:GHz%>)<br />' +
								'<strong><%:Bitrate%>:</strong> %s <%:Mbit/s%><br />',
								icon, net.signal, net.noise,
								net.quality,
								net.link, net.ssid || '?',
								net.mode,
								net.channel, net.frequency,
								net.bitrate || '?'
						);

						if (is_assoc)
						{
							s += String.format(
								'<strong><%:BSSID%>:</strong> %s<br />' +
								'<strong><%:Encryption%>:</strong> %s',
									net.bssid || '?',
									net.encryption
							);
						}
						else
						{
							s += '<em><%:Wireless is disabled or not associated%></em>';
						}

						s += '</small></td></tr></table>';

						for (var bssid in net.assoclist)
						{
							var bss = net.assoclist[bssid];

							bss.bssid  = bssid;
							bss.link   = net.link;
							bss.name   = net.name;
							bss.ifname = net.ifname;
							bss.radio  = dev.name;

							assoclist.push(bss);
						}
					}

					if (!s)
						s = '<em><%:No information available%></em>';

					td.innerHTML = s;
				}
			}

			var ac = document.getElementById('wifi_assoc_table');
			if (ac)
			{
				/* clear all rows */
				while( ac.rows.length > 1 )
					ac.rows[0].parentNode.deleteRow(1);

				assoclist.sort(function(a, b) {
					return (a.name == b.name)
						? (a.bssid < b.bssid)
						: (a.name  > b.name )
					;
				});

				for( var i = 0; i < assoclist.length; i++ )
				{
					var tr = ac.rows[0].parentNode.insertRow(-1);
						tr.className = 'cbi-section-table-row cbi-rowstyle-' + (1 + (i % 2));

					var icon;
					var q = (-1 * (assoclist[i].noise - assoclist[i].signal)) / 5;
					if (q < 1)
						icon = "<%=resource%>/icons/signal-0.png";
					else if (q < 2)
						icon = "<%=resource%>/icons/signal-0-25.png";
					else if (q < 3)
						icon = "<%=resource%>/icons/signal-25-50.png";
					else if (q < 4)
						icon = "<%=resource%>/icons/signal-50-75.png";
					else
						icon = "<%=resource%>/icons/signal-75-100.png";

					tr.insertCell(-1).innerHTML = String.format(
						'<span class="ifacebadge" title="%q"><img src="<%=resource%>/icons/wifi.png" /> %h</span>',
						assoclist[i].radio, assoclist[i].ifname
					);

					tr.insertCell(-1).innerHTML = String.format(
						'<a href="%s">%s</a>',
							assoclist[i].link,
							'%h'.format(assoclist[i].name).nobr()
					);

					tr.insertCell(-1).innerHTML = assoclist[i].bssid;

					var host = hosts[assoclist[i].bssid];
					if (host)
						tr.insertCell(-1).innerHTML = String.format(
							'<div style="max-width:200px;overflow:hidden;text-overflow:ellipsis">%s</div>',
							((host.name && (host.ipv4 || host.ipv6))
								? '%h (%s)'.format(host.name, host.ipv4 || host.ipv6)
								: '%h'.format(host.name || host.ipv4 || host.ipv6)).nobr()
						);
					else
						tr.insertCell(-1).innerHTML = '?';

					tr.insertCell(-1).innerHTML = String.format(
						'<span class="ifacebadge" title="<%:Signal%>: %d <%:dBm%> / <%:Noise%>: %d <%:dBm%> / <%:SNR%>: %d"><img src="%s" /> %d / %d <%:dBm%></span>',
						assoclist[i].signal, assoclist[i].noise, assoclist[i].signal - assoclist[i].noise,
						icon,
						assoclist[i].signal, assoclist[i].noise
					);

					tr.insertCell(-1).innerHTML = wifirate(assoclist[i], true).nobr() + '<br />' + wifirate(assoclist[i], false).nobr();
				}

				if (ac.rows.length == 1)
				{
					var tr = ac.rows[0].parentNode.insertRow(-1);
						tr.className = 'cbi-section-table-row';

					var td = tr.insertCell(-1);
						td.colSpan = 7;
						td.innerHTML = '<br /><em><%:No information available%></em>';
				}
			}
			<% end %>

			var e;

			if (e = document.getElementById('ethinfo'))			{
				var ports = eval('(' + info.ethinfo + ')');
				var tmp = "";
				for (var i in ports)
				{
					tmp = tmp + String.format(
							'<td style="text-align:center"><span style="line-height:25px">%s</span><br /><small><img src="<%=resource%>/icons/%s" /><br />%s<br />%s</small></td>',							ports[i].name,
							ports[i].status ? 'port_up.png' : 'port_down.png',
							ports[i].speed,
							ports[i].duplex ? '<%:full-duplex%>' : '<%:half-duplex%>');
				};
				e.innerHTML = "<tr>" + tmp + "</tr>";
			}

			if (e = document.getElementById('localtime'))
				e.innerHTML = info.localtime;

			if (e = document.getElementById('uptime'))
				e.innerHTML = String.format('%t', info.uptime);

			if (e = document.getElementById('runtime'))
                                e.innerHTML = info.runtime;

                        if (e = document.getElementById('userinfo'))
				e.innerHTML = info.userinfo;

			if (e = document.getElementById('cpuinfo'))
				e.innerHTML = info.cpuinfo;
				
			if (e = document.getElementById('cpuusage'))
				e.innerHTML = info.cpuusage;

			if (e = document.getElementById('loadavg'))
				e.innerHTML = String.format(
					'%.02f, %.02f, %.02f',
					info.loadavg[0] / 65535.0,
					info.loadavg[1] / 65535.0,
					info.loadavg[2] / 65535.0
				);

			if (e = document.getElementById('memtotal'))
				e.innerHTML = progressbar(
					Math.floor(((info.memory.free + info.memory.buffered) / 1048576) + (info.memcached / 1024)) + " <%:MB%>",
					Math.floor(info.memory.total / 1048576) + " <%:MB%>"
				);

			if (e = document.getElementById('membuff'))
				e.innerHTML = progressbar(
					Math.floor(info.memory.buffered / 1048576) + " <%:MB%>",
					Math.floor(info.memory.total / 1048576) + " <%:MB%>"
				);

			if (e = document.getElementById('swaptotal'))
				e.innerHTML = progressbar(
					Math.floor(info.swap.free / 1048576) + " <%:MB%>",
					Math.floor(info.swap.total / 1048576) + " <%:MB%>"
				);

			if (e = document.getElementById('swapfree'))
				e.innerHTML = progressbar(
					Math.floor(info.swap.free / 1048576) + " <%:MB%>",
					Math.floor(info.swap.total / 1048576) + " <%:MB%>"
				);

			if (e = document.getElementById('conns'))
				e.innerHTML = progressbar(info.conncount, info.connmax);

		}
	);
//]]></script>

<h2 name="content"><%:Status%></h2>

<fieldset class="cbi-section">
	<legend><%:System%></legend>

	<table width="100%" cellspacing="10">
		<tr><td width="33%"><%:Hostname%></td><td><%=luci.sys.hostname() or "?"%></td></tr>
		<tr><td width="33%"><%:Model%></td><td><%=pcdata(boardinfo.model or "?")%> <%=luci.sys.exec("cat /etc/bench.log") or " "%></td></tr>
		<tr><td width="33%"><%:CPU Info%></td><td id="cpuinfo">-</td></tr>
		<tr><td width="33%"><%:Firmware Version%></td><td>
			<%=pcdata(ver.distname)%> <%=pcdata(ver.distversion)%> /
			<%=pcdata(ver.luciname)%> (<%=pcdata(ver.luciversion)%>)
		</td></tr>
		<tr><td width="33%"><%:Kernel Version%></td><td><%=unameinfo.release or "?"%></td></tr>
		<tr><td width="33%"><%:Local Time%></td><td id="localtime">-</td></tr>
		<tr><td width="33%"><%:Uptime%></td><td id="runtime">-</td></tr>
		<tr><td width="33%"><%:Load Average%></td><td id="loadavg">-</td></tr>
		<tr><td width="33%"><%:CPU usage (%)%></td><td id="cpuusage">-</td></tr>
	</table>
</fieldset>

<fieldset class="cbi-section">
	<legend><%:Memory%></legend>

	<table width="100%" cellspacing="10">
		<tr><td width="33%"><%:Total Available%></td><td id="memtotal">-</td></tr>
		<tr><td width="33%"><%:Buffered%></td><td id="membuff">-</td></tr>
	</table>
</fieldset>

<% if swapinfo.total > 0 then %>
<fieldset class="cbi-section">
	<legend><%:Swap%></legend>

	<table width="100%" cellspacing="10">
		<tr><td width="33%"><%:Total Available%></td><td id="swaptotal">-</td></tr>
		<tr><td width="33%"><%:Free%></td><td id="swapfree">-</td></tr>
	</table>
</fieldset>
<% end %>

<fieldset class="cbi-section">
	<legend><%:Interfaces%></legend>

	<table width="100%" cellspacing="10" id="ethinfo">
	</table>
</fieldset>

<fieldset class="cbi-section">
	<legend><%:Network%></legend>

	<table width="100%" cellspacing="10">
		<tr><td width="33%" style="vertical-align:top"><%:IPv4 WAN Status%></td><td>
			<table><tr>
				<td id="wan4_i" style="width:16px; text-align:center; padding:3px"><img src="<%=resource%>/icons/ethernet_disabled.png" /><br /><small>?</small></td>
				<td id="wan4_s" style="vertical-align:middle; padding: 3px"><em><%:Collecting data...%></em></td>
			</tr></table>
		</td></tr>
		<% if has_ipv6 then %>
		<tr><td width="33%" style="vertical-align:top"><%:IPv6 WAN Status%></td><td>
			<table><tr>
				<td id="wan6_i" style="width:16px; text-align:center; padding:3px"><img src="<%=resource%>/icons/ethernet_disabled.png" /><br /><small>?</small></td>
				<td id="wan6_s" style="vertical-align:middle; padding: 3px"><em><%:Collecting data...%></em></td>
			</tr></table>
		</td></tr>
		<% end %>
		<tr><td width="33%"><%:Online Users%></td><td id="userinfo">0</td></tr>
		<tr><td width="33%"><%:Active Connections%></td><td id="conns">-</td></tr>
	</table>
</fieldset>

<% if has_dhcp then %>
<fieldset class="cbi-section">
	<legend><%:DHCP Leases%></legend>

	<table class="cbi-section-table" id="lease_status_table">
		<tr class="cbi-section-table-titles">
			<th class="cbi-section-table-cell"><%:Hostname%></th>
			<th class="cbi-section-table-cell"><%:IPv4-Address%></th>
			<th class="cbi-section-table-cell"><%:MAC-Address%></th>
			<th class="cbi-section-table-cell"><%:Leasetime remaining%></th>
		</tr>
		<tr class="cbi-section-table-row">
			<td colspan="4"><em><br /><%:Collecting data...%></em></td>
		</tr>
	</table>
</fieldset>

<% if has_ipv6 then %>
<fieldset class="cbi-section" style="display:none">
	<legend><%:DHCPv6 Leases%></legend>

	<table class="cbi-section-table" id="lease6_status_table">
		<tr class="cbi-section-table-titles">
			<th class="cbi-section-table-cell"><%:Host%></th>
			<th class="cbi-section-table-cell"><%:IPv6-Address%></th>
			<th class="cbi-section-table-cell"><%:DUID%></th>
			<th class="cbi-section-table-cell"><%:Leasetime remaining%></th>
		</tr>
		<tr class="cbi-section-table-row">
			<td colspan="4"><em><br /><%:Collecting data...%></em></td>
		</tr>
	</table>
</fieldset>
<% end %>
<% end %>

<% if has_dsl then %>
<fieldset class="cbi-section">
       <legend><%:DSL%></legend>
       <table width="100%" cellspacing="10">
               <tr><td width="33%" style="vertical-align:top"><%:DSL Status%></td><td>
                       <table><tr>
                               <td id="dsl_i" style="width:16px; text-align:center; padding:3px"><img src="<%=resource%>/icons/ethernet_disabled.png" /><br /><small>?</small></td>
                               <td id="dsl_s" style="vertical-align:middle; padding: 3px"><em><%:Collecting data...%></em></td>
                       </tr></table>
               </td></tr>
       </table>
</fieldset>
<% end %>

<% if has_wifi then %>
<fieldset class="cbi-section">
	<legend><%:Wireless%></legend>

	<table id="wifi_status_table" width="100%" cellspacing="10">
		<tr><td><em><%:Collecting data...%></em></td></tr>
	</table>
</fieldset>
<% end %>

<%+footer%>
