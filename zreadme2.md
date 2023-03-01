actions load module jac_nlp.tfm_ner
actions load module jac_nlp.use_enc

actions load local utils/model/local/local_module.py
actions load local utils/model/local/flow.py
actions load local utils/model/local/tobu.py
actions load module jac_nlp.sbert_sim


graph delete active:graph
jac build main.jac
graph create -set_active true
sentinel register -set_active true -mode ir main.jir

walker run init


jsserv makemigrations base
jsserv makemigrations
jsserv migrate
jsserv runserver 0.0.0.0:8008

jsserv createsuperuser

login http://localhost:8008



graph get -mode dot -o .main.dot
dot -Tpng .main.dot -o .main.png

pip install jaseci --upgrade
pip install jac_nlp --upgrade
pip install jaseci-serv --upgrade


pip install jaseci==1.4.0.9
pip install jac_nlp==1.4.0.9
pip install jaseci-serv==1.4.0.9


walker run tfm_ner_train -ctx "{\"train_file\": \"utils/data/tfm_train.json\"}"
walker run tfm_ner_infer -ctx "{\"labels\": [\"number\",\"accountName\",\"month\",\"accountNumber\"]}"
walker run tfm_ner_infer -ctx "{\"labels\": [\"event\",\"name\",\"activity\",\"emotion\",\"people\",\"subject\",\"age\",\"location\"]}"
walker run tfm_ner_save_model -ctx "{\"model_path\": \"tfm_ner_model\"}"
walker run tfm_ner_load_model -ctx "{\"model_path\": \"tfm_ner_model\"}"
walker run tfm_ner_delete

Todo
`````

