/*
 * az0x-img: read the headers of an AZ01 v1 update image on the device.
 *
 *   az0x-img info  IMAGE        human-readable summary
 *   az0x-img shell IMAGE PART   shell variables for one partition:
 *                               VERSION= OFF= LEN= COMP= SHA1=
 *   az0x-img compat IMAGE       exit 0 if the image names one of this
 *                               device's device-tree compatibles
 *   az0x-img cat IMAGE PART     write one partition's payload (still
 *                               compressed) to stdout
 *
 * Hashing and unpacking are left to sha1sum and unxz. Format: docs/BOOT_CHAIN.md, tools/az0x_img.py.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

#define MAX_PARTS 16
#define MAX_STRS 32

struct part {
	char name[64], comp[32], sha1[41];
	uint64_t off, len;
};

struct image {
	char version[128], desc[256];
	char compat[MAX_STRS][128];
	int ncompat;
	struct part parts[MAX_PARTS];
	int nparts;
};

static const char *err;

static uint64_t align(uint64_t n, uint64_t a) { return (n + a - 1) / a * a; }

struct rd { const unsigned char *b; size_t n, pos; };

static int u32(struct rd *r, uint32_t *v)
{
	if (r->pos + 4 > r->n) { err = "truncated header"; return -1; }
	const unsigned char *p = r->b + r->pos;
	*v = p[0] | p[1] << 8 | p[2] << 16 | (uint32_t)p[3] << 24;
	r->pos += 4;
	return 0;
}

static int str(struct rd *r, char *out, size_t outsz)
{
	uint32_t n;
	if (u32(r, &n)) return -1;
	if (r->pos + align((uint64_t)n + 1, 4) > r->n) { err = "truncated string"; return -1; }
	if (r->b[r->pos + n] != 0) { err = "string not NUL terminated"; return -1; }
	if (out) {
		size_t c = n < outsz - 1 ? n : outsz - 1;
		memcpy(out, r->b + r->pos, c);
		out[c] = 0;
	}
	r->pos += align((uint64_t)n + 1, 4);
	return 0;
}

static int blob(struct rd *r, unsigned char *out, size_t outsz, uint32_t *len)
{
	if (u32(r, len)) return -1;
	if (r->pos + align(*len, 4) > r->n) { err = "truncated blob"; return -1; }
	if (out) memcpy(out, r->b + r->pos, *len < outsz ? *len : outsz);
	r->pos += align(*len, 4);
	return 0;
}

static int read_image(const char *path, struct image *img)
{
	static unsigned char head[64 * 1024];
	struct stat st;
	FILE *f = fopen(path, "rb");
	if (!f) { err = strerror(errno); return -1; }
	if (fstat(fileno(f), &st)) { err = strerror(errno); goto bad; }
	size_t n = fread(head, 1, sizeof head, f);
	struct rd r = { head, n, 0 };
	uint32_t ver, hlen, cnt, tmp;

	memset(img, 0, sizeof *img);
	if (n < 4 || memcmp(head, "AZ01", 4)) { err = "not an AZ01 image"; goto bad; }
	r.pos = 4;
	if (u32(&r, &ver)) goto bad;
	if (ver != 1) { err = "AZ01 format version is not 1 (newer versions are signed)"; goto bad; }
	if (u32(&r, &hlen) || str(&r, img->version, sizeof img->version)) goto bad;
	if (u32(&r, &cnt)) goto bad;
	for (uint32_t i = 0; i < cnt; i++) {
		char *dst = img->ncompat < MAX_STRS ? img->compat[img->ncompat++] : NULL;
		if (str(&r, dst, 128)) goto bad;
	}
	if (u32(&r, &cnt)) goto bad;
	for (uint32_t i = 0; i < cnt; i++)
		if (u32(&r, &tmp)) goto bad;
	if (str(&r, img->desc, sizeof img->desc)) goto bad;
	if (r.pos != hlen) { err = "header length mismatch"; goto bad; }

	uint64_t pos = align(hlen, 8);
	for (;;) {
		unsigned char pre[16];
		static unsigned char ph[4096];
		if (fseeko(f, pos, SEEK_SET) || fread(pre, 1, 16, f) != 16) { err = "missing EOF record"; goto bad; }
		struct rd pr = { pre, 16, 4 };
		uint32_t rhlen, lo, hi;
		u32(&pr, &rhlen); u32(&pr, &lo); u32(&pr, &hi);
		uint64_t plen = (uint64_t)hi << 32 | lo;
		if (!memcmp(pre, "EOF\0", 4)) {
			if (rhlen != 16 || plen || pos + 16 != (uint64_t)st.st_size) { err = "bad EOF record or trailing data"; goto bad; }
			break;
		}
		if (memcmp(pre, "PART", 4)) { err = "unknown record"; goto bad; }
		if (rhlen < 16 || rhlen > sizeof ph) { err = "bad PART header length"; goto bad; }
		if (img->nparts >= MAX_PARTS) { err = "too many partitions"; goto bad; }
		if (fseeko(f, pos, SEEK_SET) || fread(ph, 1, rhlen, f) != rhlen) { err = "truncated PART header"; goto bad; }
		struct rd rr = { ph, rhlen, 16 };
		struct part *p = &img->parts[img->nparts++];
		if (str(&rr, p->name, sizeof p->name) || str(&rr, p->comp, sizeof p->comp) || u32(&rr, &cnt)) goto bad;
		for (uint32_t i = 0; i < cnt; i++) {
			char algo[32];
			unsigned char val[64];
			uint32_t vlen;
			if (str(&rr, algo, sizeof algo) || blob(&rr, val, sizeof val, &vlen)) goto bad;
			if (!strcasecmp(algo, "sha1") && vlen == 20)
				for (int k = 0; k < 20; k++)
					sprintf(p->sha1 + 2 * k, "%02x", val[k]);
		}
		if (rr.pos != rhlen) { err = "PART header length mismatch"; goto bad; }
		p->off = pos + rhlen;
		p->len = plen;
		if (p->off + plen > (uint64_t)st.st_size) { err = "payload runs past end of file"; goto bad; }
		pos = align(p->off + plen, 8);
	}
	fclose(f);
	return 0;
bad:
	fclose(f);
	return -1;
}

static int device_compatible(const struct image *img)
{
	char dt[4096];
	FILE *f = fopen("/proc/device-tree/compatible", "rb");
	if (!f) return 0;
	size_t n = fread(dt, 1, sizeof dt - 1, f);
	fclose(f);
	dt[n] = 0;
	for (size_t i = 0; i < n; i += strlen(dt + i) + 1)
		for (int c = 0; c < img->ncompat; c++)
			if (!strcmp(dt + i, img->compat[c]))
				return 1;
	return 0;
}

int main(int argc, char **argv)
{
	static struct image img;

	if (argc < 3) {
		fprintf(stderr, "usage: az0x-img info|compat IMAGE\n"
				"       az0x-img shell|cat IMAGE PART\n");
		return 2;
	}
	if (read_image(argv[2], &img)) {
		fprintf(stderr, "az0x-img: %s: %s\n", argv[2], err);
		return 1;
	}
	if (!strcmp(argv[1], "info")) {
		printf("version:     %s\ndescription: %s\ncompatible: ", img.version, img.desc);
		for (int c = 0; c < img.ncompat; c++)
			printf(" %s", img.compat[c]);
		printf("\n");
		for (int i = 0; i < img.nparts; i++)
			printf("part %-8s %-5s %llu bytes sha1 %s\n", img.parts[i].name,
			       img.parts[i].comp, (unsigned long long)img.parts[i].len,
			       img.parts[i].sha1[0] ? img.parts[i].sha1 : "(none)");
		return 0;
	}
	if (!strcmp(argv[1], "compat"))
		return device_compatible(&img) ? 0 : 1;
	if (!strcmp(argv[1], "shell") && argc > 3) {
		for (int i = 0; i < img.nparts; i++) {
			struct part *p = &img.parts[i];
			if (strcmp(p->name, argv[3]))
				continue;
			/* Only safe characters go into shell assignments. */
			for (char *s = p->comp; *s; s++)
				if (!strchr("abcdefghijklmnopqrstuvwxyz0123456789", *s)) *s = '_';
			printf("OFF=%llu\nLEN=%llu\nCOMP=%s\nSHA1=%s\n",
			       (unsigned long long)p->off, (unsigned long long)p->len,
			       p->comp, p->sha1);
			return 0;
		}
		fprintf(stderr, "az0x-img: no partition '%s' in image\n", argv[3]);
		return 1;
	}
	if (!strcmp(argv[1], "cat") && argc > 3) {
		for (int i = 0; i < img.nparts; i++) {
			struct part *p = &img.parts[i];
			if (strcmp(p->name, argv[3]))
				continue;
			static char buf[1 << 16];
			FILE *f = fopen(argv[2], "rb");
			if (!f || fseeko(f, p->off, SEEK_SET)) {
				perror("az0x-img");
				return 1;
			}
			for (uint64_t left = p->len; left; ) {
				size_t want = left < sizeof buf ? left : sizeof buf;
				size_t got = fread(buf, 1, want, f);
				if (!got) {
					fprintf(stderr, "az0x-img: short read\n");
					return 1;
				}
				if (fwrite(buf, 1, got, stdout) != got) {
					perror("az0x-img: write");
					return 1;
				}
				left -= got;
			}
			if (fflush(stdout)) {
				perror("az0x-img: write");
				return 1;
			}
			fclose(f);
			return 0;
		}
		fprintf(stderr, "az0x-img: no partition '%s' in image\n", argv[3]);
		return 1;
	}
	fprintf(stderr, "az0x-img: unknown command\n");
	return 2;
}
