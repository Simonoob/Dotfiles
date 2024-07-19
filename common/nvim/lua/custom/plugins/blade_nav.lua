-- used to navigate Blade and Livewire components using `gf`
-- the plugin also adds an nvim-cmp source and adds it to the sources list
return {
  'ricardoramirezr/blade-nav.nvim',
  dependencies = {
    'hrsh7th/nvim-cmp', -- nvim-cmp
  },
  ft = { 'blade', 'php' }, -- optional, improves startup time
}
