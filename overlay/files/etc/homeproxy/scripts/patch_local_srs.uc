'use strict';
/*
 * 离线规则集: 把 bypass_mainland_china 模式下的 remote SRS 换成本地文件,
 * 避免“没有 WAN / 还没有代理出口时先要靠代理下载规则”的死循环。
 * 在 generate_client.uc 之后由 /etc/init.d/homeproxy 调用 (见 99-homeproxy-offline-srs)。
 */
import { readfile, writefile, stat } from 'fs';

const json_path = '/var/run/homeproxy/sing-box-c.json';
const res_dir = '/etc/homeproxy/resources';

let s = readfile(json_path);
if (!s)
	exit(0);

function patch_tag(tag, url) {
	let local = res_dir + '/' + tag + '.srs';
	if (!stat(local))
		return;

	let old = sprintf(
		'\t\t\t{\n\t\t\t\t"type": "remote",\n\t\t\t\t"tag": "%s",\n\t\t\t\t"format": "binary",\n\t\t\t\t"url": "%s",\n\t\t\t\t"download_detour": "main-out"\n\t\t\t}',
		tag, url
	);
	let neu = sprintf(
		'\t\t\t{\n\t\t\t\t"type": "local",\n\t\t\t\t"tag": "%s",\n\t\t\t\t"format": "binary",\n\t\t\t\t"path": "%s"\n\t\t\t}',
		tag, local
	);
	s = replace(s, old, neu);
}

patch_tag('geoip-cn', 'https://fastly.jsdelivr.net/gh/1715173329/IPCIDR-CHINA@rule-set/cn.srs');
patch_tag('geosite-cn', 'https://fastly.jsdelivr.net/gh/1715173329/sing-geosite@rule-set-unstable/geosite-geolocation-cn.srs');
patch_tag('geosite-noncn', 'https://fastly.jsdelivr.net/gh/1715173329/sing-geosite@rule-set-unstable/geosite-geolocation-!cn.srs');

writefile(json_path, s);
