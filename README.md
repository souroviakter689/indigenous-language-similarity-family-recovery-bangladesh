# Language Similarity and Family Recovery in Low-Resource Indigenous Languages of Bangladesh

### Self-Trained Word Embeddings, Linguistic Validation, and Surface-Overlap Analysis

## Overview

This research investigates language similarity and linguistic family recovery among eight Indigenous languages of Bangladesh using self-trained Word2Vec embeddings.

The study compares two Word2Vec training objectives, Skip-gram and Continuous Bag of Words (CBOW), to investigate whether distributional representations learned from a multilingual corpus can recover known linguistic groupings.

Beyond embedding-based similarity, the research evaluates clustering against known linguistic families and compares the learned representations with a character-based edit-distance baseline.

The study also investigates the relationship between embedding distances, character-level surface overlap, and geographic distances. These analyses help examine whether the observed similarities reflect meaningful linguistic structure or are influenced by orthographic and phonetic overlap.

The overall objective is to assess the usefulness, limitations, and reproducibility of self-trained word embeddings for low-resource Indigenous language analysis.

---

## Research Objectives

The study addresses the following objectives:

1. **Embedding Comparison:** Compare Skip-gram and CBOW using their ability to recover known linguistic groupings.

2. **Language Similarity:** Construct cosine similarity matrices to investigate relationships among Indigenous languages, Bangla, and English.

3. **Linguistic Family Recovery:** Evaluate hierarchical clustering against predefined linguistic-family labels using the Adjusted Rand Index (ARI).

4. **Baseline Comparison:** Compare embedding-based clustering with a non-embedding edit-distance baseline.

5. **Surface-Overlap Analysis:** Investigate whether character-level orthographic or phonetic overlap is associated with embedding-based similarity.

6. **Geographic Validation:** Examine the relationship between geographic distance and embedding distance using a permutation-based Mantel test.

7. **Reproducibility:** Document the experimental configuration, preprocessing decisions, and validation procedures required to reproduce the reported findings.

---

## Languages Covered

The study includes eight Indigenous languages of Bangladesh.

| Language | Role |
|---|---|
| Chakma | Indigenous language |
| Marma | Indigenous language |
| Garo | Indigenous language |
| Kokborok | Indigenous language |
| Santali | Indigenous language |
| Khasi | Indigenous language |
| Mro | Indigenous language |
| Hajong | Indigenous language |
| Bangla | Reference language |
| English | Reference language |

The Indigenous languages are evaluated against predefined linguistic-family labels used in the clustering analysis.

These labels are treated as evaluation references rather than conclusions established by the embedding models.

---

## Dataset Description

The dataset contains parallel Bangla, English, and Indigenous-language sentences.

### Dataset structure

| Column | Description |
|---|---|
| `Bangla` | Bangla reference sentence |
| `English` | English reference sentence |
| `Indigenous` | Sentence in an Indigenous language |
| `Language` | Corresponding Indigenous-language label |

### Dataset statistics

| Statistic | Reported value |
|---|---:|
| Original rows | 5,906 |
| Rows after preprocessing | 5,842 |
| Number of Indigenous languages | 8 |
| Unique Bangla sentences | 786 |
| Unique English sentences | 810 |

### Language-wise record counts after preprocessing

| Language | Number of records |
|---|---:|
| Chakma | 543 |
| Garo | 736 |
| Hajong | 775 |
| Khasi | 765 |
| Kokborok | 759 |
| Marma | 800 |
| Mro | 697 |
| Santali | 767 |
| **Total** | **5,842** |

### Dataset source

The dataset was collected from Multiling Cloud.

Dataset redistribution and public availability must comply with the original source's terms. Dataset access instructions will be provided in `data/README.md`.

---

## Methodology

The research pipeline consists of the following stages.

### 1. Data Preprocessing

The original dataset is processed to remove incomplete and empty records, standardize text formatting, retain the eight target Indigenous languages, and remove exact duplicate sentence records.

The resulting dataset contains 5,842 records.

Bangla and English reference sentences are separately deduplicated before constructing the Word2Vec training corpus to reduce repeated contributions from parallel translations.

### 2. Multilingual Training Corpus

The training corpus combines:

- Indigenous-language sentences
- Unique Bangla reference sentences
- Unique English reference sentences

The objective is to train both embedding models in a shared vocabulary and representation space.

### 3. Word2Vec Training

Two Word2Vec architectures are trained from scratch:

- Skip-gram
- Continuous Bag of Words (CBOW)

The models are trained on the combined corpus rather than using pretrained multilingual sentence-embedding models.

Consequently, this study compares Word2Vec training objectives; it does not constitute a direct comparison of pretrained SBERT, mBERT, or XLM-R models.

### 4. Sentence and Language Representations

Sentence representations are constructed by averaging the embeddings of available tokens.

Language-level representations are then obtained by averaging the sentence representations for each language.

This produces one language vector for each of the eight Indigenous languages, Bangla, and English.

### 5. Cosine Similarity

Cosine similarity is calculated between the resulting language vectors.

Separate similarity matrices are generated for Skip-gram and CBOW.

These matrices are used to investigate pairwise language relationships and identify the most similar Indigenous language to each reference language.

### 6. Hierarchical Clustering

Hierarchical clustering is performed using average linkage.

The number of clusters is set to three for the linguistic-family recovery experiment.

The resulting clusters are compared against predefined linguistic-family labels.

### 7. Linguistic Validation Using ARI

The Adjusted Rand Index (ARI) measures agreement between the clustering assignments and the reference family labels.

ARI is used to compare:

- Skip-gram embeddings
- CBOW embeddings
- Edit-distance baseline

### 8. Edit-Distance Baseline

A non-embedding baseline is constructed using normalized Levenshtein edit distances between aligned Indigenous-language sentence pairs.

Sentence pairs are aligned through their shared Bangla source sentences.

The resulting language-level distance matrix is clustered using the same average-linkage procedure, and the clustering is evaluated using ARI.

The corrected implementation removes duplicate Bangla keys before joining language-specific records.

### 9. Surface-Overlap Analysis

Character-trigram profiles are constructed for the Indigenous-language corpora.

Cosine-based character-trigram distances are compared with the embedding distance matrices using Spearman Mantel tests with 9,999 permutations.

This analysis examines whether the learned representations track orthographic or phonetic surface overlap.

### 10. Geographic Validation

Geographic distances between representative language locations are compared with embedding distances using Spearman Mantel tests with 9,999 permutations.

The interpretation of this analysis depends on the validity and representativeness of the geographic coordinates.

The coordinates must be independently verified before the results are treated as final geographic evidence.

---

## Experimental Configuration

The reported R implementation uses the following configuration.

| Parameter | Value |
|---|---|
| Programming language | R |
| Embedding architecture | Skip-gram and CBOW |
| Embedding dimension | 100 |
| Context window | 5 |
| Training iterations | 20 |
| Minimum word count | 1 |
| Random seed | 42 |
| Clustering algorithm | Hierarchical clustering |
| Linkage method | Average linkage |
| Number of clusters | 3 |
| Surface-overlap test | Spearman Mantel test |
| Geographic validation | Spearman Mantel test |
| Permutations | 9,999 |

These values describe the documented run configuration. The final repository script should be checked to ensure that it uses the same settings.

---

## Experimental Results

### 1. Linguistic Family Recovery

The reported ARI results are:

| Method | ARI |
|---|---:|
| Skip-gram | 0.6067 |
| CBOW | 0.6067 |
| Corrected edit-distance baseline | 0.3000 |

Both embedding models achieve the same reported ARI.

The embedding-based approaches therefore outperform the corrected edit-distance baseline in this clustering evaluation, while neither Skip-gram nor CBOW demonstrates superiority over the other based on ARI alone.

The ARI measures agreement with the chosen reference labels; it does not independently establish the historical or genealogical relationships among languages.

### 2. Similarity to Bangla and English

The reported Skip-gram results identify:

| Reference language | Most similar Indigenous language | Cosine similarity |
|---|---|---:|
| Bangla | Marma | 0.3108 |
| English | Chakma | 0.3723 |

These values describe the learned language-level representations in the current experimental setup.

They should not be interpreted as definitive measures of semantic similarity or genealogical relatedness.

### 3. Most Similar Indigenous-Language Pairs

The reported pairwise similarity analysis identifies the following high-similarity pairs:

| Model | Language pair | Cosine similarity |
|---|---|---:|
| Skip-gram | Garo–Mro | 0.981 |
| CBOW | Marma–Khasi | 0.970 |

The similarities indicate that the learned language vectors are close in the respective embedding spaces.

However, high cosine similarity does not, by itself, prove that two languages belong to the same family. Shared orthographic patterns, phonetic overlap, corpus composition, and training characteristics may influence these values.

### 4. Surface-Overlap Validation

Character-trigram distances are compared with embedding distances using Mantel tests.

| Model | Mantel correlation (r) | p-value |
|---|---:|---:|
| Skip-gram | 0.8407 | 0.0001 |
| CBOW | 0.8188 | 0.0004 |

Both reported correlations are positive and statistically significant.

The results indicate a strong association between character-level surface distances and embedding distances.

This is an important limitation of the study: the learned representations may substantially reflect orthographic or phonetic surface overlap rather than independent semantic or genealogical structure.

### 5. Geographic Validation

The reported geographic Mantel results are:

| Model | Mantel correlation (r) | p-value |
|---|---:|---:|
| Skip-gram | 0.1446 | 0.2286 |
| CBOW | 0.1270 | 0.2534 |

Neither reported correlation is statistically significant at the conventional 0.05 level.

However, these results must be interpreted cautiously because the geographic coordinates require verification and may not adequately represent the distributions of the language communities.

These values should not be treated as final validated geographic findings until the coordinate assignments have been checked.

### 6. Summary of Reported Findings

The current reported results suggest that:

1. Both Skip-gram and CBOW achieve an ARI of 0.6067.
2. The corrected edit-distance baseline achieves an ARI of 0.3000.
3. Embedding distances show strong associations with character-trigram distances.
4. The reported geographic Mantel correlations are not statistically significant.
5. Surface-level orthographic or phonetic overlap is an important potential confound in interpreting embedding-based language similarity.

The numerical findings must be kept consistent with the final, verified analysis outputs before publication of the repository.

---

## Repository Structure

The repository is organized as follows:

```text
indigenous-language-similarity-family-recovery-bangladesh/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── R/
│   └── ids_project.R
│
├── data/
│   └── README.md
│
├── results/
│   ├── similarity_matrix_skipgram.csv
│   ├── similarity_matrix_cbow.csv
│   ├── edit_distance_baseline_matrix.csv
│   └── results_summary.csv
│
├── figures/
│   ├── heatmap_skipgram.png
│   ├── heatmap_cbow.png
│   ├── dendrogram_skipgram.png
│   ├── dendrogram_cbow.png
│   ├── pca_skipgram.png
│   └── pca_cbow.png
│
└── docs/
    ├── methodology.md
    └── reproducibility.md
```

This structure describes the intended organization. Files should be added as they are generated and verified.

The research paper PDF is intentionally not included while the conference decision is pending.

---

## Requirements

The R implementation uses packages including:

- `word2vec`
- `tidyverse`
- `textclean`
- `proxy`
- `pheatmap`
- `dendextend`
- `mclust`
- `geosphere`
- `Rtsne`
- `ggrepel`
- `vegan`

A compatible R installation and the required package versions are needed to reproduce the analysis.

---

## How to Run

1. Install R.
2. Install the required R packages.
3. Obtain the dataset according to the instructions in `data/README.md`.
4. Place the dataset in the expected location or configure the dataset path.
5. Open the R script in `R/`.
6. Check the preprocessing and model configuration.
7. Run the analysis.
8. Inspect the generated similarity matrices, clustering assignments, ARI results, Mantel statistics, and figures.

See `docs/reproducibility.md` for detailed instructions.

The repository should only be described as fully reproducible after the complete pipeline has been tested from start to finish.

---

## Limitations

Several limitations should be considered when interpreting the findings.

### Surface-Overlap Confounding

The strong association between character-trigram distances and embedding distances suggests that the learned representations may be substantially influenced by orthographic or phonetic patterns.

### Small Number of Language-Level Observations

The clustering and Mantel analyses operate on eight Indigenous languages. Results based on this small number of language-level observations require cautious interpretation.

### Geographic Representativeness

A single representative location may not capture the full geographic distribution of a language community. Geographic findings depend on independently verified and appropriate location assignments.

### Corpus and Training Effects

Vocabulary coverage, sentence composition, tokenization, corpus size, and Word2Vec training characteristics may influence the resulting language vectors.

### Interpretation of Linguistic Families

Agreement with predefined family labels evaluates clustering consistency with those labels. It does not independently prove genealogical relationships or replace historical-linguistic evidence.

---

## Data Availability

The dataset was collected from Multiling Cloud.

Access, use, and redistribution must comply with the original source's terms.

The dataset is not included in this repository at this stage.

---

## Research Paper

The associated research paper is currently under conference consideration.

The paper PDF is intentionally not included in this repository while the conference decision is pending.

---

## Citation

Citation information will be added when the final bibliographic details are available.

---

## Acknowledgements

The original dataset source and any external resources used in this research should be acknowledged in accordance with their respective terms.
