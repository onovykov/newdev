# 🧹 Queueable Job Utility Pack

## 📦 Склад

| Файл | Призначення |
|------|--------------|
| `GenericQueueHardDelete.cls` | Основний клас, який видаляє записи сторінками |
| `MonitorQueueJobs.apex` | Показує прогрес і помилки Queueable-джобів |
| `AbortQueueJobs.apex` | Зупиняє всі активні джоби цього класу |

---

## ⚙️ Запуск

### 1️⃣ Запустити видалення
```bash
sf apex run --target-org newdev -f scripts/apex/GenericQueueHardDelete.apex
```

або прямо в консоль Apex:
```apex
System.enqueueJob(new GenericQueueHardDelete('Lot__c', null, true, 200));
```

---

### 2️⃣ Моніторинг
```bash
sf apex run -f scripts/apex/MonitorQueueJobs.apex
```

**Що буде в консолі:**
- кількість Completed, Processing, Queued;
- тривалі джоби (>10 сек);
- останні помилки з `ExtendedStatus`.

---

### 3️⃣ Зупинити завислі черги
```bash
sf apex run -f scripts/apex/AbortQueueJobs.apex
```

> ⚠️ За замовчуванням абортує Queueable старші 5 хвилин;  
> змінити можна у файлі → `MINUTES_OLD = 5`.

---

## 💡 Поради

| Ситуація | Що робити |
|-----------|------------|
| Джоба “висить” у `Processing` >10 хв | зменшити `pageSize` до 100 |
| З’являються `UNABLE_TO_LOCK_ROW` | зменшити `pageSize` і запустити заново |
| У `Apex Jobs` видно багато `Completed` | усе ок, працює сторінками |
| Треба перевірити, чи закінчило | повторно запусти `MonitorQueueJobs.apex` |
| Треба зупинити всі поточні | запусти `AbortQueueJobs.apex` |

---

## 🧠 Команда для Makefile (опціонально)
```makefile
monitor:
	sf apex run -f scripts/apex/MonitorQueueJobs.apex

abort:
	sf apex run -f scripts/apex/AbortQueueJobs.apex
```

→ запуск:
```bash
make monitor
make abort
```
