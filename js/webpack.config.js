const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
    mode: "production",
    entry: "./src/main.ts",
    output: {
        filename: "../../assets/static/js/gotty-bundle.js"
    },
    devtool: "source-map",
    resolve: {
        extensions: [".ts", ".tsx", ".js"],
    },
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                loader: "ts-loader",
                exclude: /node_modules/
            },
            {
                test: /\.js$/,
                include: /node_modules/,
                loader: 'license-loader'
            }
        ]
    },
    optimization: {
        minimize: true,
        minimizer: [new TerserPlugin()],
    },
    performance: {
        maxEntrypointSize: 4096000,
        maxAssetSize: 4096000
    }
};
