# NNDescent-I/O Deterministic version
# Benchmarking NNDescent - Deterministic

Questa cartella contiene un ambiente sperimentale che ho realizzato per testare **il determinismo** della fase di *merge* dell’algoritmo NNDescent in un contesto multi-GPU. L’obiettivo era capire se, a parità di input, il sistema producesse sempre lo stesso grafo k-NN finale — e, in caso contrario, da dove derivasse la variabilità.

---

## Cosa ho fatto

### 1. Divisione del programma in due fasi distinte

Ho modificato `main.cu` e `gen_large_knngraph.cu` per separare esplicitamente due modalità:

- `build_only`: costruisce i grafi k-NN iniziali per ogni shard e li salva.
- `merge_only`: legge da disco i grafi già costruiti e li unisce.

In questo modo posso testare **solo la fase di merge**, evitando ogni forma di randomizzazione che potrebbe arrivare dalla costruzione iniziale.

---

### 2. Script per creare grafi dummy ma deterministici

Ho scritto da zero `generate_dummy_knn.cu`, un eseguibile indipendente che:

- legge un file `.txt` di vettori (es. `SK_data.txt`);
- lo converte in `.fvecs`;
- calcola **le vere distanze euclidee** tra tutti i punti;
- seleziona, per ogni punto, i `k` vicini più vicini;
- genera due grafi k-NN coerenti:
  - con label **locali** (relativi allo shard);
  - con label **globali** (relativi all’intero dataset);
- salva tutto in due file `.bin` compatibili col sistema esistente.

Tutto è fatto in maniera deterministica grazie a:

- seed fissato per le randomizzazioni, modificando le funzioni:
    - DevRNGLongLong nel file knncuda_tools.cu
    - xorshift64star

Ho integrato questo eseguibile nel `CMakeLists.txt`:

```cmake
add_executable(generate_dummy_knn generate_dummy_knn.cu)
target_link_libraries(generate_dummy_knn PRIVATE knncuda ${CUDA_cublas_LIBRARY} ${CUDA_curand_LIBRARY} nvToolsExt)
set_property(TARGET generate_dummy_knn PROPERTY CUDA_ARCHITECTURES 50)


## Come usare il programma
0. clonare la repo con build_from_scratch.sh e poi entrare nella cartella "benchmarking_NNDescent_Deterministic"

1. cambiare il numero di gpu / tipo:
    a. in gen_large_knngraph.cu modificare "#define NUM_GPU 3"
    b. im base al tipo di gpu cambiare in CMakeLists: "-arch=sm_80" e "CUDA_ARCHITECTURES 80"
    c. sempre in CMakeLists commentare / scommentare come indicato le linee di codice in base a se eseguito su macchina di laboratorio (BigMama) oppure supercomputer (Cineca Leonard)

2. cambiare il numero k di vicini:
    a. cambiare in nndescent.cuh "const int NEIGHB_NUM_PER_LIST = 12;"
    b. cambiare in main.cu "#define K_neighbors 12 "

3. create il dataset da utilizzare:
    a. in ogni caso prima di utilizzare i dati entrare in data/artificial e scrivere: ``` python3 create.py NUM_POINTS_DATASET

4. lanciare il programma utilizzando il file sh corrispondente alla modalità di utilizzo voluta:
    a. normale esecuzione di gpuknn multimerge (con i seed fissati):
        i. runnare lo script che trasformi il dataset txt in vecs: run_3gpu_deterministic_create_vectors_datasets.sh
        ii. runnare lo script:run_3gpu_deterministic_normal.sh
    b. esecuzione solo di build_only
        i. runnare lo script che trasformi il dataset txt in vecs: run_3gpu_deterministic_create_vectors_datasets.sh
        ii. runnare lo script: run_3gpu_deterministic_build_only.sh
    c. esecuzione di generate_dummy_knn.cu:
        i. runnare lo script: run_3gpu_deterministic_generate_dummy_knn.sh
    d. esecuzione della versione merge_only (NB: solo DOPO l'esecuzione di almeno una volta build_only oppure generate_dummy_knn)
        i. runnare lo script: run_3gpu_deterministic_merge_only.sh

5. confrontare i risultati:
    a. entrare nella cartella "results"
    b. eseguire il file compare_resultsFiles.py come ``` pyhton3 compare_resultsFiles.py file1.txt file2.txt