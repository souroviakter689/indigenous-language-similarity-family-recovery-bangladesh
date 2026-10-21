# Indigenous Language Similarity and Family Recovery in Bangladesh

An R-based machine learning project exploring language similarity and linguistic family patterns among eight Indigenous languages of Bangladesh using self-trained Word2Vec embeddings.

## Overview

This project uses Word2Vec to analyze similarities among Chakma, Marma, Garo, Kokborok, Santali, Khasi, Mro, and Hajong.

It combines Skip-gram and CBOW embeddings with cosine similarity, hierarchical clustering, and linguistic-family validation to explore patterns among these languages.

The project also includes an edit-distance baseline, character-level surface-overlap analysis, and geographic-distance comparison.

## Features

- Dataset preprocessing and text normalization
- Self-trained Word2Vec embeddings
- Skip-gram and CBOW model comparison
- Language-level embedding generation
- Cosine similarity matrices
- Hierarchical clustering
- Linguistic-family evaluation using Adjusted Rand Index (ARI)
- Levenshtein edit-distance baseline
- Character-trigram surface-overlap analysis
- Geographic-distance validation
- Similarity heatmaps, dendrograms, and PCA visualizations

## Languages

**Indigenous languages**
- Chakma
- Marma
- Garo
- Kokborok
- Santali
- Khasi
- Mro
- Hajong

**Reference languages**
- Bangla
- English

## Technologies Used

- R
- Word2Vec
- Skip-gram
- Continuous Bag of Words (CBOW)
- Cosine Similarity
- Hierarchical Clustering
- Adjusted Rand Index
- Levenshtein Edit Distance
- Mantel Test
- PCA and Data Visualization

## Project Workflow

1. **Data Preprocessing:** Clean sentence records, normalize text, and remove duplicates.
2. **Corpus Construction:** Combine Indigenous-language sentences with unique Bangla and English reference sentences.
3. **Embedding Training:** Train Skip-gram and CBOW Word2Vec models from scratch.
4. **Language Representation:** Generate sentence embeddings through average pooling and aggregate them into language-level vectors.
5. **Similarity Analysis:** Calculate cosine similarity between language vectors.
6. **Clustering:** Apply average-linkage hierarchical clustering.
7. **Evaluation:** Compare clustering assignments with predefined linguistic-family labels using ARI.
8. **Baseline Comparison:** Evaluate a normalized Levenshtein edit-distance baseline.
9. **Validation:** Examine character-trigram overlap and geographic-distance relationships.
10. **Visualization:** Generate heatmaps, dendrograms, and PCA plots.

## Dataset

The dataset contains parallel Bangla, English, and Indigenous-language sentences.

| Dataset Information | Value |
|---|---:|
| Original records | 5,906 |
| Records after preprocessing | 5,842 |
| Indigenous languages | 8 |
| Unique Bangla sentences | 786 |
| Unique English sentences | 810 |

### Language-wise Records

| Language | Records |
|---|---:|
| Chakma | 543 |
| Garo | 736 |
| Hajong | 775 |
| Khasi | 765 |
| Kokborok | 759 |
| Marma | 800 |
| Mro | 697 |
| Santali | 767 |

**Dataset source:** Multiling Cloud.

Dataset access and redistribution are subject to the original source's terms.

## Model Configuration

| Parameter | Value |
|---|---|
| Embedding models | Skip-gram and CBOW |
| Embedding dimensions | 100 |
| Context window | 5 |
| Training iterations | 20 |
| Minimum word count | 1 |
| Random seed | 42 |
| Clustering algorithm | Hierarchical clustering |
| Linkage method | Average linkage |
| Number of clusters | 3 |

These settings reflect the current documented implementation.

## Results

The current project results include the following reported ARI scores:

| Method | ARI |
|---|---:|
| Skip-gram | 0.6067 |
| CBOW | 0.6067 |
| Corrected edit-distance baseline | 0.3000 |

Both embedding models achieve the same reported ARI, while the corrected edit-distance baseline achieves a lower score.

### Language Similarity

The reported Skip-gram results identify:

| Reference Language | Most Similar Indigenous Language | Cosine Similarity |
|---|---|---:|
| Bangla | Marma | 0.3108 |
| English | Chakma | 0.3723 |

The highest reported Indigenous-language pair similarities are:

| Model | Language Pair | Cosine Similarity |
|---|---|---:|
| Skip-gram | Garo–Mro | 0.981 |
| CBOW | Marma–Khasi | 0.970 |

These similarities describe the learned embedding space and should not be interpreted as definitive proof of genealogical relationships.

### Surface-Overlap Analysis

| Model | Mantel Correlation | p-value |
|---|---:|---:|
| Skip-gram | 0.8407 | 0.0001 |
| CBOW | 0.8188 | 0.0004 |

The reported results indicate strong associations between character-trigram distances and embedding distances. This suggests that orthographic or phonetic surface overlap may influence the learned representations.

### Geographic-Distance Analysis

| Model | Mantel Correlation | p-value |
|---|---:|---:|
| Skip-gram | 0.1446 | 0.2286 |
| CBOW | 0.1270 | 0.2534 |

The reported geographic correlations are not statistically significant at the 0.05 level. Geographic coordinates require verification before these results can be treated as final.

*Note: Numerical results should be checked against the final verified outputs before being treated as definitive.*

## Repository Structure

```text
indigenous-language-similarity-family-recovery-bangladesh/
│
├── README.md
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

This is the intended structure; files will be added as they become available and are verified.

## Installation

Install R and the required packages:

```r
install.packages(c(
  "word2vec",
  "tidyverse",
  "textclean",
  "proxy",
  "pheatmap",
  "dendextend",
  "mclust",
  "geosphere",
  "Rtsne",
  "ggrepel",
  "vegan"
))
```

## How to Run

1. Clone or download this repository.
2. Install the required R packages.
3. Obtain the dataset according to `data/README.md`.
4. Configure the dataset path and input object in the R script.
5. Run `R/ids_project.R`.
6. Inspect the generated similarity matrices, clustering results, validation statistics, and visualizations.

See `docs/reproducibility.md` for additional instructions.

The full pipeline should be considered reproducible only after it has been tested successfully from start to finish.

## Limitations

- Learned similarities may reflect orthographic or phonetic overlap.
- Language-level comparisons involve only eight Indigenous languages.
- Geographic findings depend on the accuracy and representativeness of language-location assignments.
- Clustering agreement with predefined family labels does not independently establish genealogical relationships.

## Project Status

Project development, experimental validation, and repository organization are ongoing.

The associated paper is not included in this repository at this stage.
