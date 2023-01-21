return {
    useCanvas = require("modules.hooks.canvas"),
    useTextCanvas = require("modules.hooks.textCanvas"),
    useBoundingBox = require("modules.hooks.aabb").useBoundingBox,
    findNodeAt = require("modules.hooks.aabb").findNodeAt,
    useAnimation = require("modules.hooks.animation").useAnimation,
    tickAnimations = require("modules.hooks.animation").tickAnimations,
}
