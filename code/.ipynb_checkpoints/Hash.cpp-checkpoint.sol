#include "Hash.h"

// implemented for you - don't change this one
unsigned int DJB2(std::string key){
  unsigned int hash = 5381;
  // Leaving the debugging stuff commented out, in case you want to
  // play. It will output the hash at each incremental step so you can
  // see how it takes shape.
  //
  //  cout << "Hashing string \"" << key << "\"" << endl;
  //  cout << bitset<32>(hash) << " " << hash << endl;
  for (size_t i=0; i < key.length(); i++) {
    char c = key[i]; 
    hash = ((hash << 5) + hash) + c;
    // cout << bitset<32>(hash) << " " << hash << endl;
  }
  // cout << "Hashed string \"" << key << "\" to " << hash << endl;
  //
  // for light reading on why djb2 might not be the best
  // production-grade hash function, go to
  // http://dmytry.blogspot.com/2009/11/horrible-hashes.html
  return hash;
}

// implemented for you - don't change this one
unsigned int ModuloBucketFunc(unsigned int hashcode, unsigned int cap){
  unsigned int b = hashcode % cap;
  return b;
}

// constructor, initialize class variables and pointers here if need.
Hash::Hash(){
  // Your code here
}

//deconstructor,
Hash::~Hash(){
}

shared_ptr<hash_table> Hash::InitTable(unsigned int cap){
  shared_ptr<hash_table> ret(new hash_table);

  ret->capacity = cap;
  ret->size = 0;
  ret->occupied = 0;

  ret->table = shared_ptr<htable>(new htable(cap));

  for (unsigned int i = 0; i < cap; i++) 
    ret->table->at(i) = shared_ptr<hash_node>(NULL);

  ret->hash_func = DJB2;
  ret->bucket_func = ModuloBucketFunc;

  return ret;
}

shared_ptr<hash_node> Hash::InitNode(std::string key, unsigned int hashcode, std::string val){
  shared_ptr<hash_node> ret(new hash_node);

  ret->deleted = false;
  ret->key = key;
  ret->value = val;
  ret->hashcode = hashcode;

  return ret;
}

bool Hash::SetKVP(shared_ptr<hash_table> tbl, std::string key, std::string value){
  unsigned int hash = tbl->hash_func(key);
  unsigned int target = tbl->bucket_func(hash, tbl->capacity);
  // iterate over rest of table
  unsigned int i = target;
  while (true) {
    if (tbl->table->at(i) == NULL) {
      // empty since start
      tbl->table->at(i) = InitNode(key, hash, value);
      // update table
      tbl->size++;
      tbl->occupied++;
      return true;
    }
    shared_ptr<hash_node> cursor = tbl->table->at(i);
    if (cursor->deleted) {
      // encounter a deleted space
      cursor->hashcode = hash;
      cursor->key = key;
      cursor->value = value;
      cursor->deleted = false;
      // update table
      tbl->size++;
      return true;
    }
    if (cursor->hashcode == hash) {
      // update existing key
      cursor->value = value;
      return true;
    }
    // find next location
    i = (i + 1) % tbl->capacity;
    if (i == target) break;
  }
  return false;
}

float Hash::Load(shared_ptr<hash_table> tbl){
  return (float) tbl->size / (float) tbl->capacity;
}

std::string Hash::GetVal(shared_ptr<hash_table> tbl, std::string key){
  unsigned int hash = tbl->hash_func(key);
  unsigned int target = tbl->bucket_func(hash, tbl->capacity);
  unsigned int i = target;
  shared_ptr<hash_node> cursor = tbl->table->at(i);
  while (cursor != NULL) {
    // found
    if (cursor->hashcode == hash && !cursor->deleted) return cursor->value;
    // increment
    i = (i + 1) % tbl->capacity;
    cursor = tbl->table->at(i);
    // has looped
    if (i == target) break;
  }
  // not found
  return "";
}

bool Hash::Contains(shared_ptr<hash_table> tbl, std::string key){
  unsigned int hash = tbl->hash_func(key);
  unsigned int target = tbl->bucket_func(hash, tbl->capacity);
  unsigned int i = target;
  shared_ptr<hash_node> cursor = tbl->table->at(i);
  while (cursor != NULL) {
    // found
    if (cursor->hashcode == hash && !cursor->deleted) return true;
    // increment
    i = (i + 1) % tbl->capacity;
    cursor = tbl->table->at(i);
    // has looped
    if (i == target) break;
  }
  return false; // TODO
}

bool Hash::Remove(shared_ptr<hash_table> tbl, std::string key){
  unsigned int hash = tbl->hash_func(key);
  unsigned int target = tbl->bucket_func(hash, tbl->capacity);
  unsigned int i = target;
  shared_ptr<hash_node> cursor = tbl->table->at(i);
  while (cursor != NULL) {
    // found
    if (cursor->hashcode == hash && !cursor->deleted) {
      cursor->deleted = true;
      tbl->size--;
      return true;
    }
    // increment
    i = (i + 1) % tbl->capacity;
    cursor = tbl->table->at(i);
    // has looped
    if (i == target) break;
  }
  return false; // TODO
}

void Hash::Resize(shared_ptr<hash_table> tbl, unsigned int new_capacity){
  // save addr for deletion
  shared_ptr<vector<shared_ptr<hash_node>>> old_table = tbl->table;
  unsigned int old_cap = tbl->capacity;
  // init new table
  shared_ptr<vector<shared_ptr<hash_node>>> new_table;
  new_table = shared_ptr<htable>(new htable(new_capacity));
  for (unsigned int i = 0; i < new_capacity; i++) 
    new_table->at(i) = shared_ptr<hash_node>(NULL);
  // reset stats
  tbl->table = new_table;
  tbl->capacity = new_capacity;
  tbl->size = tbl->occupied = 0;
  // copy from old to new
  for (unsigned int i = 0; i < old_cap; i++) {
    if (!old_table->at(i)) 
      continue;
    shared_ptr<hash_node> cursor = old_table->at(i);
    SetKVP(tbl, cursor->key, cursor->value);
    cursor.reset();
  }
  // free
  old_table.reset();
}

// implemented for you - feel free to change this one
void Hash::PrintTable(shared_ptr<hash_table> tbl){
  cout << "Hashtable:" << endl;
  cout << "  capacity: " << tbl->capacity << endl;
  cout << "  size:     " << tbl->size << endl;
  cout << "  occupied: " << tbl->occupied << endl;
  cout << "  load:     " << Load(tbl) << endl;
  if (tbl->capacity < 130) {
    for (unsigned int i=0; i < tbl->capacity; i++) {
      cout << "[" << i << "]    ";
      if (!tbl->table->at(i)) {
        cout << "<empty>" << endl;
      } else if (tbl->table->at(i)->deleted) {
        cout << "<deleted>" << endl;
      } else {
        cout << "\"" << tbl->table->at(i)->key << "\" = \"" << tbl->table->at(i)->value << "\"" << endl;
      }
    }
  } else {
    cout << "    <hashtable too big to print out>" << endl;
  }
}

