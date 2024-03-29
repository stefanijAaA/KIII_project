/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  serverRuntimeConfig: {
    PROJECT_ROOT: __dirname,
  },
  experimental: {
    externalDir: true,
    runtime: 'nodejs',
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: '**',
      },
    ],
  },
  async rewrites() {
    return [
      {
        source: `${'/server'}/:ctrl*`,
        destination: `${
          process.env.BACKEND_URL ?? 'http://backend:5000'
        }/:ctrl*`,
      },
    ]
  },
}

module.exports = nextConfig
