## QuickStart

### 1. username=ubuntu
### 2. password=123456


### 3. build code
```bash
docker build -t abc .
```

### 4. run code
```bash
docker run -p 3000:3000 --rm -it --privileged abc
```

