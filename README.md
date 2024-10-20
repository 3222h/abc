## QuickStart

### 1. username=ubuntu
### 2. password=123456,ubuntu


### 3. build code
```bash
docker build -t abc .
```

### 4. run code
```bash
docker run --restart always -p 3000:3000 --privileged --name nomashine abc
```

### 4. run code
```bash
docker run -d --restart always --privileged -p 6000:3000 --name nomashine abc
```

RUN git clone https://github.com/AtsushiSaito/noVNC.git -b add_clipboard_support /usr/lib/novnc
