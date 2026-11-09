<?php

namespace App\Filament\Resources\Products\Tables;

use App\Models\Category;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;

class ProductsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                ImageColumn::make('gambar')
                    ->label('Thumbnail')
                    ->disk('public')
                    ->circular()
                    ->defaultImageUrl(url('/storage/products/default.jpg')),
                TextColumn::make('id')->sortable(),
                TextColumn::make('nama')
                    ->label('Nama Produk')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('kategori')
                    ->label('Kategori')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('harga')
                    ->label('Harga')
                    ->money('IDR', locale: 'id')
                    ->sortable(),
                TextColumn::make('stok')
                    ->label('Stok')
                    ->sortable(),
                TextColumn::make('satuan_jual')
                    ->label('Satuan'),
                IconColumn::make('tersedia')
                    ->label('Tersedia')
                    ->boolean()
                    ->sortable(),
                IconColumn::make('mudah_rusak')
                    ->label('Mudah Rusak')
                    ->boolean()
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Dibuat')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('kategori')
                    ->label('Kategori')
                    ->options(function () {
                        return Category::pluck('nama_kategori', 'nama_kategori')->toArray();
                    }),
                TernaryFilter::make('tersedia')
                    ->label('Ketersediaan'),
                TernaryFilter::make('mudah_rusak')
                    ->label('Mudah Rusak'),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make()
                    ->before(function (DeleteAction $action, \App\Models\Product $record) {
                        if ($record->orderItems()->whereHas('order', function ($query) {
                            $query->whereNotIn('status', ['selesai', 'dibatalkan']);
                        })->exists()) {
                            \Filament\Notifications\Notification::make()
                                ->title('Gagal Menghapus')
                                ->body("Produk '{$record->nama}' masih terpakai pada pesanan aktif.")
                                ->danger()
                                ->send();

                            $action->halt();
                        }

                        if ($record->orderItems()->exists()) {
                            \Filament\Notifications\Notification::make()
                                ->title('Gagal Menghapus')
                                ->body("Produk '{$record->nama}' tidak dapat dihapus karena memiliki riwayat transaksi pesanan.")
                                ->danger()
                                ->send();

                            $action->halt();
                        }
                    }),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make()
                        ->before(function (DeleteBulkAction $action, \Illuminate\Database\Eloquent\Collection $records) {
                            foreach ($records as $record) {
                                if ($record->orderItems()->exists()) {
                                    \Filament\Notifications\Notification::make()
                                        ->title('Gagal Menghapus')
                                        ->body("Sebagian produk tidak dapat dihapus karena memiliki relasi pesanan.")
                                        ->danger()
                                        ->send();

                                    $action->halt();
                                }
                            }
                        }),
                ]),
            ]);
    }
}
