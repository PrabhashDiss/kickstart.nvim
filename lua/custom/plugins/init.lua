-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local neogit = require 'custom.plugins.neogit'
local auto_session = require 'custom.plugins.auto_session'
local codecompanion = require 'custom.plugins.codecompanion'
local comment = require 'custom.plugins.comment'
local flash = require 'custom.plugins.flash'
local jdtls = require 'custom.plugins.jdtls'

return {
  neogit,
  auto_session,
  codecompanion,
  comment,
  flash,
  jdtls,
}
