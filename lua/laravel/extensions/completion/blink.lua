--- @module 'blink.cmp'
--- @class blink.cmp.Source
local nio = require("nio")
local Class = require("laravel.utils.class")

local source = Class({})

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts
  self.env = Laravel.app("laravel.core.env")
  self.templates = Laravel.app("laravel.utils.templates")
  self.environment_vars_loader = Laravel.app("laravel.loaders.environment_variables_loader")
  self.views_loader = Laravel.app("laravel.loaders.views_cache_loader")
  self.routes_loader = Laravel.app("laravel.loaders.routes_cache_loader")
  self.configs_loader = Laravel.app("laravel.loaders.configs_cache_loader")
  self.inertia_loader = Laravel.app("laravel.loaders.inertia_cache_loader")
  return self
end

function source:enabled()
  return self.env:isActive() and vim.tbl_contains({ "tinker", "blade", "php" }, vim.bo.filetype)
end

function source:get_trigger_characters()
  return { "'", '"', ":", ">" }
end

function source:get_completions(ctx, callback)
  if vim.tbl_contains({ "php", "blade", "tinker" }, vim.bo[ctx.bufnr].filetype, {}) then
    callback({ items = {} })
  end

  local line = ctx.line
  local cursor_col = ctx.cursor[2]
  local text = line:sub(1, cursor_col)

  local params = {
    context = {
      cursor_before_line = text,
      filetype = vim.bo[ctx.bufnr].filetype,
      bufnr = ctx.bufnr,
    },
  }

  local adapted_callback = function(result)
    callback({
      items = result.items,
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    })
  end

  nio.run(function()
    local views_completion = require("laravel.extensions.completion.views_completion")
    if views_completion.shouldComplete(text) then
      return views_completion.complete(self.views_loader, self.templates, params, adapted_callback)
    end

    local inertia_completion = require("laravel.extensions.completion.inertia_completion")
    if inertia_completion.shouldComplete(text) then
      return inertia_completion.complete(self.inertia_loader, self.templates, params, adapted_callback)
    end

    local configs_completion = require("laravel.extensions.completion.configs_completion")
    if configs_completion.shouldComplete(text) then
      return configs_completion.complete(self.configs_loader, self.templates, params, adapted_callback)
    end

    local routes_completion = require("laravel.extensions.completion.routes_completion")
    if routes_completion.shouldComplete(text) then
      return routes_completion.complete(self.routes_loader, self.templates, params, adapted_callback)
    end

    local env_completion = require("laravel.extensions.completion.env_vars_completion")
    if env_completion.shouldComplete(text) then
      return env_completion.complete(self.environment_vars_loader, self.templates, params, adapted_callback)
    end

    local model_completion = require("laravel.extensions.completion.model_completion")
    if model_completion.shouldComplete(text) then
      return model_completion.complete(self.templates, params, adapted_callback)
    end
  end)

  adapted_callback({ items = {} })
  return function() end
end

function source:resolve(item, callback) end

function source:execute(ctx, item, callback, default_implementation)
  -- When you provide an `execute` function, your source must handle the execution
  -- of the item itself, but you may use the default implementation at any time
  default_implementation()

  -- The callback _MUST_ be called once
  callback()
end

return source
