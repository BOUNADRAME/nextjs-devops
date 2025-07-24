import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone", // Enable standalone mode for better Docker support.
  reactStrictMode: false, // Enable React's strict mode for catching potential issues.
  eslint: {
    ignoreDuringBuilds: true, // Ceci désactivera toutes les vérifications ESLint pendant le build
  },
};

export default nextConfig;
