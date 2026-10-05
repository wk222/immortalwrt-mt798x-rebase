'use strict';
/* 离线规则集: 将 bypass_mainland 的 remote SRS 换成本地文件 (无需 WAN). */
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

if (match(s, '"default_interface":'))
	s = replace(s, '"default_interface":', '"auto_detect_interface": false,\n\t\t"default_interface":');

writefile(json_path, s);
