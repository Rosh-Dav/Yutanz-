| Model                     | Accuracy | Macro-P | Macro-R | Macro-F1 |
|---------------------------|----------|---------|---------|----------|
| VADER only                | 0.5605   | 0.5503  | 0.5346  | 0.5329   |
| Original cardiffnlp model | 0.6996   | 0.6923  | 0.6939  | 0.6902   |
| Fine-tuned model          | 0.7601   | 0.7523  | 0.7531  | 0.7511   |

Per class (fine-tuned): negative P 0.7122 R 0.8114 F1 0.7586 (1580),
neutral P 0.7018 R 0.6420 F1 0.6706 (1503), positive P 0.8429 R 0.8060 F1 0.8240 (2103)

Confusion matrix (rows = true negative/neutral/positive, columns = predicted in the same order):
[[1282, 209, 89], [311, 965, 227], [207, 201, 1695]]