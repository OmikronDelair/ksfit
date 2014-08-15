Ksfit::Application.routes.draw do
   root to: 'ksfs#index'
   post 'ksfs/upload'
   post 'ksfs/ksf_it'
end
